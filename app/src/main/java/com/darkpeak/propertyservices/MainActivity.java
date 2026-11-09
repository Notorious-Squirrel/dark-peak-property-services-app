package com.darkpeak.propertyservices;
import android.app.Activity;
import android.os.Bundle;
import android.content.Intent;
import android.net.Uri;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.webkit.WebResourceRequest;
import android.widget.Toast;
public class MainActivity extends Activity {
    @Override public void onCreate(Bundle state) {
        super.onCreate(state);
        WebView view = new WebView(this);
        view.getSettings().setJavaScriptEnabled(true);
        view.getSettings().setDomStorageEnabled(true);
        view.setWebViewClient(new WebViewClient() {
            @Override public boolean shouldOverrideUrlLoading(WebView v, WebResourceRequest request) {
                Uri uri = request.getUrl();
                if ("mailto".equalsIgnoreCase(uri.getScheme())) {
                    try { startActivity(new Intent(Intent.ACTION_SENDTO, uri)); }
                    catch (Exception ex) { Toast.makeText(MainActivity.this,"Please install an email app to send your enquiry",Toast.LENGTH_LONG).show(); }
                    return true;
                }
                return !"file".equalsIgnoreCase(uri.getScheme());
            }
        });
        setContentView(view);
        view.loadUrl("file:///android_asset/index.html");
    }
}