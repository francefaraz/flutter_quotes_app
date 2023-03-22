import 'package:flutter/material.dart';
import 'package:make_urself_inspire/main.dart';
import 'dart:async';

class Splash extends StatefulWidget {
  const Splash({Key? key}) : super(key: key);

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> {

  @override
  void initState(){
    super.initState();
    _navigatetohome();

  }

  _navigatetohome()async{
    await Future.delayed(Duration(milliseconds:1500),(){});
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>MyHomePage(title: "INSPIRING QUOTES")));

  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Image(image: AssetImage("assests/img/icon.png")),
            Container(
              child: new Image.asset('assets/img/icon.png'),
                // height: 100,
                // width: 100,
                // color:Colors.blue
            ),
            Container(
                child: Text('azad ', style: TextStyle(
                    fontSize: 26, fontWeight: FontWeight.bold),)
            ),
          ],
        ),
      ),
    );
  }
}
