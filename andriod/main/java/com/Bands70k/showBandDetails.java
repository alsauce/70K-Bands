package com.Bands70k;

/**
 * Created by rdorn on 7/25/15.
 */

import android.app.Activity;

import android.content.Intent;
import android.os.Bundle;

import android.util.Log;

import android.webkit.JavascriptInterface;
import android.webkit.WebSettings;
import android.webkit.WebView;


public class showBandDetails extends Activity {
    /** Called when the activity is first created. */

    private WebView mWebView;
    private String htmlText;
    private String mustButtonColor;
    private String mightButtonColor;
    private String wontButtonColor;
    private String unknownButtonColor;
    private Boolean inLink = false;

    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.band_details);

        initializeWebContent();
    }

    private void initializeWebContent (){

        mWebView = (WebView) findViewById(R.id.detailWebView);
        mWebView.setWebViewClient(new customWebViewClient());

        WebSettings webSettings = mWebView.getSettings();
        webSettings.setJavaScriptEnabled(true);


        mWebView.addJavascriptInterface(new Object() {

            @JavascriptInterface
            public void performClick(String value) {
                Log.d("Variable is", value);
                rankStore.saveBandRanking(getBandInfo.getSelectedBand(), resolveValue(value));

                Intent showDetails = new Intent(showBandDetails.this, showBandDetails.class);
                startActivity(showDetails);
            }

        }, "ok");

        mWebView.addJavascriptInterface(new Object() {

            @JavascriptInterface
            public void webLinkClick() {
                inLink = true;
            }

        }, "link");

        createDetailHTML();
    }

    @Override
    protected void onPause() {
        super.onPause();
        mWebView.reload();
    }

    @Override
    public void onResume() {
        super.onResume();
        setContentView(R.layout.band_details);
        initializeWebContent();
        inLink = false;
    }

    @Override
    public void onBackPressed() {

        if (inLink){
            mWebView.onPause();
            Intent showDetails = new Intent(showBandDetails.this, showBandDetails.class);
            startActivity(showDetails);

        } else {
            Intent showDetails = new Intent(showBandDetails.this, showBands.class);
            startActivity(showDetails);
        }
    }

    public void SetButtonColors() {

        rankStore.getBandRankings();

        if (rankStore.getRankForBand(getBandInfo.getSelectedBand()).equals(staticVariables.mustSeeIcon)){
            mustButtonColor = "Silver";
            mightButtonColor = "WhiteSmoke";
            wontButtonColor = "WhiteSmoke";
            unknownButtonColor = "WhiteSmoke";

        } else if (rankStore.getRankForBand(getBandInfo.getSelectedBand()).equals(staticVariables.mightSeeIcon)){
            mustButtonColor = "WhiteSmoke";
            mightButtonColor = "Silver";
            wontButtonColor = "WhiteSmoke";
            unknownButtonColor = "WhiteSmoke";

        } else if (rankStore.getRankForBand(getBandInfo.getSelectedBand()).equals(staticVariables.wontSeeIcon)){
            mustButtonColor = "WhiteSmoke";
            mightButtonColor = "WhiteSmoke";
            wontButtonColor = "Silver";
            unknownButtonColor = "WhiteSmoke";

        } else {
            mustButtonColor = "WhiteSmoke";
            mightButtonColor = "WhiteSmoke";
            wontButtonColor = "WhiteSmoke";
            unknownButtonColor = "Silver";
        }
    }

    private String resolveValue (String value){

        String newValue;

        if (value.equals(staticVariables.mustSeeKey)){
            newValue = staticVariables.mustSeeIcon;

        } else if (value.equals(staticVariables.mightSeeKey)){
            newValue = staticVariables.mightSeeIcon;

        } else if (value.equals(staticVariables.wontSeeKey)){
            newValue = staticVariables.wontSeeIcon;

        } else if (value.equals(staticVariables.unknownKey)){
            newValue = staticVariables.unknownIcon;

        } else {
            newValue = value;
        }

        return newValue;
    }

    public void createDetailHTML () {

        String bandName = getBandInfo.getSelectedBand();

        SetButtonColors();

            htmlText =
                    "<html><div style='height:90vh;'>" +
                            "<center>" + bandName + "</center><br>" +
                            "<center><img src='" + getBandInfo.getImageUrl(bandName) + "'</img>" +
                            "<center><ul style='list-style-type:none;text-align:left;margin-left:60px'>" +
                            "<li><a href='" + getBandInfo.getOfficalWebLink(bandName) + "' onclick='link.webLinkClick()'>Offical Link</a></li>" +
                            "<li><a href='" + getBandInfo.getWikipediaWebLink(bandName) + "' onclick='link.webLinkClick()'>Wikipedia</a></li>" +
                            "<li><a href='" + getBandInfo.getYouTubeWebLink(bandName) + "' onclick='link.webLinkClick()'>YouTube</a></li>" +
                            "<li><a href='" + getBandInfo.getMetalArchivesWebLink(bandName) + "' onclick='link.webLinkClick()'>Metal Archives</a></li>" +
                            "</ul></center><br></div><div style='height:10vh;'><table width=100%><tr width=100%>" +
                            "<td><button style='background:" + unknownButtonColor + "' type=button value=" + staticVariables.unknownKey + " onclick='ok.performClick(this.value);'>" + staticVariables.unknownIcon + "</button></td>" +
                            "<td><button style='background:" + mustButtonColor + "' type=button value=" + staticVariables.mustSeeKey + " onclick='ok.performClick(this.value);'>" + staticVariables.mustSeeIcon + " " + getResources().getString(R.string.must) + "</button></td>" +
                            "<td><button style='background:" + mightButtonColor + "' type=button value=" + staticVariables.mightSeeKey + " onclick='ok.performClick(this.value);'>" + staticVariables.mightSeeIcon + " " + getResources().getString(R.string.might) + "</button></td>" +
                            "<td><button style='background:" + wontButtonColor + "' type=button value=" + staticVariables.wontSeeKey + " onclick='ok.performClick(this.value);'>" + staticVariables.wontSeeIcon + " " + getResources().getString(R.string.wont) + "</button></td>" +
                            "</tr></table></div>" +
                            "</html>";

            mWebView.loadDataWithBaseURL("", htmlText, "text/html", "UTF-8", "");

    }
}
