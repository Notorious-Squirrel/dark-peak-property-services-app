// Supabase Edge Function: ai-price. Deploy with JWT verification enabled.
// Required secret: GEMINI_API_KEY. SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are injected by Supabase.
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
Deno.serve(async req => {
 const headers={"Content-Type":"application/json","Access-Control-Allow-Origin":"*","Access-Control-Allow-Headers":"authorization,apikey,content-type","Access-Control-Allow-Methods":"POST,OPTIONS"};
 const reply=(body:unknown,status=200)=>new Response(JSON.stringify(body),{status,headers});
 if(req.method==="OPTIONS")return new Response(null,{headers});
 if(req.method!=="POST")return reply({error:"Method not allowed"},405);
 const token=req.headers.get("Authorization")?.replace(/^Bearer\s+/i,"");
 if(!token)return reply({error:"Sign in to use AI pricing"},401);
 const url=Deno.env.get("SUPABASE_URL")!,anon=Deno.env.get("SUPABASE_ANON_KEY")!,service=Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,key=Deno.env.get("GEMINI_API_KEY");
 if(!key)return reply({error:"AI pricing has not been configured yet"},503);
 const userClient=createClient(url,anon,{global:{headers:{Authorization:"Bearer "+token}}});
 const {data:{user},error:authError}=await userClient.auth.getUser(token);
 if(authError||!user)return reply({error:"Session expired"},401);
 let input:any;try{input=await req.json()}catch{return reply({error:"Invalid request"},400)}
 const {business_id,name,category,description,postcode}=input||{};
 if(!/^[0-9a-f-]{36}$/i.test(business_id||"")||typeof name!=="string"||!name.trim()||name.length>160||typeof category!=="string"||category.length>100||typeof description!=="string"||description.length>1200||typeof postcode!=="string"||postcode.length>30)return reply({error:"Enter valid job details and postcode"},400);
 const {data:member}=await userClient.from("business_members").select("business_id").eq("business_id",business_id).eq("user_id",user.id).maybeSingle();
 if(!member)return reply({error:"Not authorised for this business"},403);
 const admin=createClient(url,service);
 const {error:claimError}=await userClient.rpc("claim_free_ai_price",{p_business:business_id});
 if(claimError)return reply({error:claimError.message},429);
 try{
  const prompt="You are a cautious UK trade pricing assistant. Estimate a fair LOCAL MARKET PRICE for the job, not a contractor cost-plus quote. You do not have live access to competitor quotes. Do not claim verified current local prices or fabricate sources. Give GBP figures including assumptions on labour, materials and VAT. Provide valid JSON only with keys low,typical,high,recommended (numeric GBP), confidence (low/medium), explanation (string max 400 characters), assumptions (string max 300 characters). Ensure low<=typical<=high and recommended within range. Job: "+JSON.stringify({name,category,description,postcode});
  const response=await fetch("https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent",{method:"POST",headers:{"Content-Type":"application/json","x-goog-api-key":key},body:JSON.stringify({contents:[{parts:[{text:prompt}]}],generationConfig:{responseMimeType:"application/json",temperature:0.2}})});
  if(!response.ok)throw Error("AI provider unavailable ("+response.status+")");
  const raw=await response.json();const data=JSON.parse(raw.candidates?.[0]?.content?.parts?.[0]?.text||"null");
  if(!data||!["low","typical","high","recommended"].every(k=>typeof data[k]==="number"&&Number.isFinite(data[k])&&data[k]>=0)||data.low>data.typical||data.typical>data.high||data.recommended<data.low||data.recommended>data.high)throw Error("AI returned an invalid estimate");
  const {data:usage}=await admin.from("ai_pricing_usage").select("used").eq("business_id",business_id).single();
  return reply({estimate:{low:data.low,typical:data.typical,high:data.high,recommended:data.recommended,confidence:data.confidence==="medium"?"medium":"low",explanation:String(data.explanation||"").slice(0,400),assumptions:String(data.assumptions||"").slice(0,300)},remaining:Math.max(0,3-(usage?.used??3))});
 }catch(e){await admin.rpc("refund_free_ai_price",{p_business:business_id});return reply({error:String(e instanceof Error?e.message:e)},502)}
});
