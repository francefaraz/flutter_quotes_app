import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:make_urself_inspire/splash.dart';
import 'package:screenshot/screenshot.dart';
import 'package:http/http.dart' as http;
import 'package:clipboard/clipboard.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'package:share/share.dart';
import 'dart:convert';

import 'package:toast/toast.dart';

AppOpenAd? appOpenAd;
String appOpenAdUnitId = Platform.isAndroid
    ? 'ca-app-pub-3940256099942544/3419835294'
    : 'ca-app-pub-3940256099942544/5662855259';


Future<void> loadAd() async{
  await AppOpenAd.load(adUnitId:appOpenAdUnitId,
                       request: const AdRequest(),
                       adLoadCallback: AppOpenAdLoadCallback(
                           onAdLoaded: (ad){
                             print("ad is loaded");
                             appOpenAd=ad;
                             appOpenAd!.show();
                           },
                           onAdFailedToLoad: (error){
                             print("APPOPEN ADD LOADING FAILED");
                           }
                       ),
                      orientation: AppOpenAd.orientationPortrait
  );

}
void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  await loadAd();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
  runApp(const MyApp());
}
const maxAttempts=3;
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Motivation Quotes',
      theme: ThemeData(
        primarySwatch: Colors.lightBlue,
      ),
      home: Splash(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {


  late BannerAd staticAd;
  bool _isStaticAdLoaded=false;

  late InterstitialAd interstitialAd;
  bool _isInterstitialAdLoaded=false;
  int interstitialAttempts=0;

  late RewardedAd rewardedAd;
  bool _isRewardedAdLoaded=false;
  int rewardedAttempts=0;



  final bannerAdUnitId = Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/6300978111'
      : 'ca-app-pub-3940256099942544/2934735716';

  final interstitialAdUnitId = Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/1033173712'
      : 'ca-app-pub-3940256099942544/4411468910';

  final rewardedAdUnitId = Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/5224354917'
      : 'ca-app-pub-3940256099942544/1712485313';

  void loadStaticBannerAd(){


    staticAd=BannerAd(
      adUnitId: bannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
    debugPrint('$ad loaded.');
    setState(() {
      _isStaticAdLoaded = true;
    });
    },
        onAdFailedToLoad: (ad, err) {
          debugPrint('BannerAd failed to load: $err');
          // Dispose the ad here to free resources.
          ad.dispose();
        },
      )
    );
    staticAd.load();
  }

  void createInterstitialAd(){
    InterstitialAd.load(adUnitId: interstitialAdUnitId, request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
            onAdLoaded: (ad){
              debugPrint('$ad loaded.');
              interstitialAd=ad;

              interstitialAttempts=0;
            },
            onAdFailedToLoad: (error){
              debugPrint('InterstitialAd failed to load: $error');
                interstitialAttempts++;

                if(interstitialAttempts<=maxAttempts){
                  createInterstitialAd();
                }


            }));
  }

  void showInterstitialAd(){
    if(interstitialAd==null){
      print("trying to showInterstitial before loading");
      return;
    }
    interstitialAd!.fullScreenContentCallback=FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        setState(() {
          _isInterstitialAdLoaded = true;
        });
        print("ad loaded ${ad}");},
        onAdDismissedFullScreenContent: (ad) {
          // Dispose the ad here to free resources.
          ad.dispose();
          createInterstitialAd();
        },
        onAdFailedToShowFullScreenContent: (ad, err) {
          // Dispose the ad here to free resources.
          ad.dispose();
          print("Failed to show ad:$ad error is $err");
          createInterstitialAd();
        },

    );
    interstitialAd!.show();
    interstitialAd!=null;
  }


  //rewarded video ad show and create


  void createRewardedAd(){
    RewardedAd.load(adUnitId: rewardedAdUnitId, request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
            onAdLoaded: (ad){
              debugPrint('$ad loaded.');
              rewardedAd=ad;

              rewardedAttempts=0;
            },
            onAdFailedToLoad: (error){
              debugPrint('InterstitialAd failed to load: $error');
              rewardedAttempts++;

              if(rewardedAttempts<=maxAttempts){
                createRewardedAd();
              }


            }));
  }

  void showRewardedAd(){
    if(rewardedAd==null){
      print("trying to show rewarded before loading");
      return;
    }
    rewardedAd!.fullScreenContentCallback=FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        setState(() {
          _isRewardedAdLoaded = true;
        });
        print("ad loaded ${ad}");},
      onAdDismissedFullScreenContent: (ad) {
        // Dispose the ad here to free resources.
        ad.dispose();
        createRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (ad, err) {
        // Dispose the ad here to free resources.
        ad.dispose();
        print("Failed to show ad:$ad error is $err");
        createRewardedAd();
      },

    );
    rewardedAd!.show(onUserEarnedReward: (ad,reward){
      print("rewarded is ${reward.amount} and type is ${reward.type} ");
    });
    rewardedAd!=null;
  }


  late String quote,owner,imgLink;
  bool isWorking=false;
  final grey=Colors.blueGrey;
  late ScreenshotController screenshotController;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    screenshotController = ScreenshotController();
    quote="";
    owner="";
    imgLink="";
    getQuote();
    loadStaticBannerAd();
    createInterstitialAd();
    createRewardedAd();
  }
  getQuote() async {
    offline(){
      setState(() {
        owner="Shaik Muneer";
        quote="Love is the hardest habit to break \n and the most difficult to satisfy.";
        imgLink="";
        isWorking=false;
      });
    }
      try{
        setState(() {
          isWorking=true;
          quote=owner=imgLink="";

        });
        var uri = Uri.parse('http://api.forismatic.com/api/1.0/');

        var response = await http.post(
            uri,
            body: {"method": "getQuote", "format": "json", "lang": "en"}
        );

        setState(() {
          try{
            var res=jsonDecode(response.body);
            owner=res['quoteAuthor'].toString().trim();
            quote=res['quoteText'].toString().replaceAll("&"," ");
            getImg(owner);

          }catch(e) {getQuote();}
        });

      }
      catch(e){
        offline();
      }


  }
  copyQuote(){
    FlutterClipboard.copy(quote+"\n-"+owner).then((result){
      ToastContext().init(context);

      Toast.show("Quote Copied",duration:Toast.lengthLong);
      showInterstitialAd();
    });
  }

  shareQuote() async {
    final directory = (await getApplicationDocumentsDirectory()).path; //from path_provide package
    String fileName ='screenshots${DateTime.now().toIso8601String()}.png';
    var path='$directory';
    print("hello ${path} filename is ${fileName}");
    screenshotController.captureAndSave(
        path, //set path where screenshot will be saved
        fileName:fileName
    )
        .then((res) {
          print("hello ${res} filename");
      print("HERE WE HAVE ${path}");
      Share.shareFiles([res.toString()], text: quote);
      showRewardedAd();
    }).catchError((onError) {
      print("error re farazzzzzz ${onError}");
      print(onError);
    });
    // await screenshotController.captureAndSave(
    //     path, //set path where screenshot will be saved
    //     fileName:fileName
    // );
    // await Share.shareFiles([path], text: quote);
  }

  getImg(String name) async {
    var image = await http.get(Uri.parse(
        "https://en.wikipedia.org/w/api.php?action=query&generator=search&gsrlimit=1&prop=pageimages%7Cextracts&pithumbsize=400&gsrsearch=" +
            name +
            "&format=json"));

    setState(() {
      try {
        var res = json.decode(image.body)["query"]["pages"];
        res = res[res.keys.first];
        imgLink = res["thumbnail"]["source"];
      } catch (e) {
        imgLink = "";
      }
      isWorking = false;
    });
  }

  Widget drawImg() {
    if (imgLink.isEmpty) {
      return Image.asset("assets/img/offline.jpg", fit: BoxFit.cover);
    } else {
      return Image.network(imgLink, fit: BoxFit.cover);
    }
  }


  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: grey,
      body: Screenshot(
        controller: screenshotController,
        child: Stack(
            alignment: Alignment.center,
            fit: StackFit.expand,
            children: <Widget>[
              drawImg(),
              Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0, 0.6, 1],
                      colors: [
                        grey.withAlpha(70),
                        grey.withAlpha(220),
                        grey.withAlpha(255),
                      ],
                    ),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 100),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        if (_isStaticAdLoaded)
                          Container(
                          child:AdWidget(ad:staticAd,),
                          width: staticAd!.size.width.toDouble(),
                          height: staticAd!.size.height.toDouble(),
                            alignment: Alignment.topCenter,
                          ),


                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                              text: quote != null ? '“ ' : "",
                              style: TextStyle(
                                  fontFamily: "Ic",
                                  color: Colors.green,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 30),
                              children: [
                                TextSpan(
                                    text: quote != null ? quote : "",
                                    style: TextStyle(
                                        fontFamily: "Ic",
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 22)),
                                TextSpan(
                                    text: quote != null ? '”' : "",
                                    style: TextStyle(
                                        fontFamily: "Ic",
                                        fontWeight: FontWeight.w700,
                                        color: Colors.green,
                                        fontSize: 30))
                              ]),
                        ),
                        Text(owner.isEmpty ? "" : "\n" + owner,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontFamily: "Ic",
                                color: Colors.white,
                                fontSize: 18)),
                      ])),
              AppBar(
                title: Text(
                  "Motivational Quote",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w400, fontSize: 12),
                ),
                backgroundColor: Colors.transparent,
                elevation: 0,
                centerTitle: true,
              ),
            ]),
      ),
      floatingActionButton: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            InkWell(
              onTap: !isWorking ? getQuote : null,
              child: Icon(Icons.refresh, size: 35, color: Colors.white),
            ),
            InkWell(
              onTap: quote.isNotEmpty ? copyQuote : null,
              child: Icon(Icons.content_copy, size: 30, color: Colors.white),
            ),
            InkWell(
              onTap: quote.isNotEmpty ? shareQuote : null,
              child: Icon(Icons.share, size: 30, color: Colors.white),
            )
          ]),
    );
  }
}

