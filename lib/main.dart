import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:flutter/material.dart';
import 'package:homeapp/firebase_options.dart';
import 'package:toggle_switch/toggle_switch.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Home App',
      theme: ThemeData.dark(),
      home: const DefaultTabController(
        length: 3,
        child: MyHomePage(title: 'Home App'),
      )
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _fb = FirebaseDatabase.instance;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late TextEditingController _textcontroller;
  var data = {};
  String id2save = "";
  String name2save = "";

  bool isLoading = true;
  int isHome = 0;
  var subList = [];


  @override
  void initState(){
    super.initState();
    readData();
    initSubs();
    initMessaging();
    _textcontroller = TextEditingController();
  }

  void initMessaging () async {
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    String? token = await _fcm.getToken(
      vapidKey: "BMhXoP_s9aw-kWGFoB20oSLeo2EN1wmqUw6EmIT-fj-I0r7QuxXdAjqti3L_m1xhwih1_JGXcB7SOQybS-DPW8I",
    );
  }

  void initSubs() async {
    var tempSub = _fb.ref().child("temp").onValue.listen((event) {
      var ss = event.snapshot.value;
      setState(() {
        data.update("temp", (value) => ss);
      });      
    });
    subList.add(tempSub);
    var rfSub = _fb.ref().child("rfidLogs").onChildAdded.listen((event) async {
      var ss = await _fb.ref().child("rfidLogs").get().then((value) =>value.children);
      var tmp = buildRfTab(List<DataSnapshot>.from(ss).reversed);
      //print(data);
      setState(() {
        data.update("rLogs", (value) => tmp);
      });      
    });
    subList.add(rfSub);
    var mtSub = _fb.ref().child("motionLogs").onChildAdded.listen((event) async {
      var ss2 = await _fb.ref().child("motionLogs").get().then((value) =>value.children);
      var tmp2 = buildMtTab(List<DataSnapshot>.from(ss2).reversed);
      setState(() {
        data.update("mLogs", (value) => tmp2);
      });      
    });
    subList.add(mtSub);


  }

  List<Container> buildRfTab ( Iterable<DataSnapshot> children ) {
    var list = <Container>[];
    int c = 0;
    list.add(
        Container(
          color: Colors.blueGrey,
          height: 50,
          child: 
            const Center(child: Text("Door Logs"))   
        )
    );
    for (var e in children) {
      c++;
        if (c == 11){break;}
        var row = Container(
          color: Colors.white12,
          height: 50,
          child: 
            Center(child: Text("Person-${e.value} entrance attempt at: ${e.key}"))   
        );
        list.add(row);
    }
    return list;
  }

  List<Container> buildMtTab ( Iterable<DataSnapshot> children ) {
    var list = <Container>[];
    int c = 0;
    list.add(
        Container(
          color: Colors.blueGrey,
          height: 50,
          child: 
            const Center(child: Text("Motion Sensor Logs"))   
        )
    );
    for (var e in children) {
      c++;
        if (c == 11){break;}
        var row = Container(
          color: Colors.white12,
          height: 50,
          child: 
            Center(child: Text("Motion detected at time: ${e.key}"))   
        );
        list.add(row);
    }
    return list;
  }

  Future<void> readData() async {
    final ref = _fb.ref();
    data["temp"] = 0;
    data["rLogs"] = <Container>[];
    data["mLogs"] = <Container>[];
    final ssTem = await ref.child("temp").get();
    final ssRf = await ref.child("rfidLogs").get();
    final ssMot = await ref.child("motionLogs").get();
    final ssHome = await ref.child("isInHome").get();
    if (ssTem.exists  && ssRf.exists && ssMot.exists && ssHome.exists){
      data["temp"] = ssTem.value;
      var tmp = buildRfTab(List<DataSnapshot>.from(ssRf.children).reversed);
      var tmp2 = buildMtTab(List<DataSnapshot>.from(ssMot.children).reversed);
      setState(() {
        data["rLogs"] = List<Widget>.from(tmp);
        data["mLogs"] = List<Widget>.from(tmp2);
        isHome = int.parse(ssHome.value.toString());
        isLoading = false;
        }
      );
    }
    else {
      //print("Data incomplete...");
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Home App"),
        bottom: const TabBar(
          tabs: [
            Tab(icon: Icon(Icons.house_rounded),),
            Tab(icon: Icon(Icons.run_circle_outlined),),
            Tab(icon: Icon(Icons.man_rounded),),
          ],
        ),
      ),
      body: isLoading ? 
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: const [CircularProgressIndicator()]
      )
      : 
      TabBarView(children: [
        Container(
        padding: const EdgeInsets.all(15),
        child:Center(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                    CircularPercentIndicator(
                    radius: 60.0,
                    percent: (data["temp"]-5)/40 <= 1.0 ? ((data["temp"]-5)/40 > 0.0 ? ((data["temp"]-5)/40) : 0.0) : 1.0,
                    center: Text("${data["temp"]}"),
                    footer: const Text("\nTemperature #Celcius\n")
                    ),
                    ToggleSwitch(
                      initialLabelIndex: isHome,
                      totalSwitches: 2,
                      animate: false,
                      customWidths: const [100,80],
                      labels: const ["Not at home", "At home"],
                      onToggle: (index){
                        if (index == 0) {
                          setState(() {
                            isHome = 0;
                            _fb.ref("isInHome").set(isHome.toString());
                          });
                        }
                        else {
                          setState(() {
                            isHome = 1;
                            _fb.ref("isInHome").set(isHome.toString());
                          });
                        }
                      },
                    )
                  ],
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(child: 
                    ListView(
                      padding: const EdgeInsets.all(5),
                      scrollDirection: Axis.vertical,
                      shrinkWrap: true,
                      children: data["rLogs"],
                    ),
                  )
                ],
              ),
            ],
          )
        ),
      ),
      Container(
        padding: const EdgeInsets.all(15),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Expanded(child: 
                    ListView(
                      padding: const EdgeInsets.all(5),
                      scrollDirection: Axis.vertical,
                      shrinkWrap: true,
                      children: data["mLogs"],
                    ),
                  ),
              ],
          )
         ),
      ),
      Container(
        padding: const EdgeInsets.all(15),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    TextFormField(
                      decoration: const InputDecoration(
                        hintText: 'Card ID',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (String? value){
                        if (value == null || value.isEmpty) {
                          return "Please enter card ID.";
                        }
                        return null;
                      },
                      onSaved: (value){
                        setState(() {
                          id2save = value!;
                        });
                      },
                    ),
                    TextFormField(
                      decoration: const InputDecoration(
                        hintText: 'Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (String? value){
                        if (value == null || value.isEmpty) {
                          return "Please enter Name.";
                        }
                        return null;
                      },
                      onSaved: (value) {
                        setState(() {
                          name2save = value!;
                        });
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: ElevatedButton(
                        onPressed: () {
                          if(_formKey.currentState!.validate()){
                            _formKey.currentState!.save();
                            setState(() {
                              _fb.ref("cards/$id2save").set(name2save);
                            });
                            showDialog(
                              context: context,
                              builder: (BuildContext context){
                                return AlertDialog(
                                  content: Text('Saved card $id2save for user $name2save!'),
                                  actions: <Widget>[
                                    TextButton(
                                      onPressed: () {Navigator.pop(context);},
                                      child: const Text('OK'),
                                    ),
                                  ],
                                );
                              });
                          }
                        },
                        child: const Text('Submit'),
                      ),
                    ),
                  ],
                  ),
                ),
            ],
          ),
        ),
      ),
      ])
    );
  }

  @override
  void dispose() {
    for (var s in subList) {
      s.cancel();
    }
    _textcontroller.dispose();
    super.dispose();
  }
}
