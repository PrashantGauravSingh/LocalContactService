import 'package:contacts_service/contacts_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: ContactListPage(),
    );
  }
}

class ContactListPage extends StatefulWidget {
  @override
  _ContactListPageState createState() => _ContactListPageState();
}

class _ContactListPageState extends State<ContactListPage> {
  List<Contact> _contacts;
  String filter;
  final TextEditingController searchName = TextEditingController();


  @override
  initState() {
    super.initState();
    refreshContacts();
    searchName.addListener(() {
      setState(() {
        filter = searchName.text;
      });
    });
  }

  @override  void dispose() {
    searchName.dispose();
    super.dispose();
  }

  refreshContacts() async {
    PermissionStatus permissionStatus = await _getContactPermission();
    if (permissionStatus == PermissionStatus.granted) {
      // Load without thumbnails initially.
      var contacts = (await ContactsService.getContacts(withThumbnails: false))
          .toList();
//      var contacts = (await ContactsService.getContactsForPhone("8554964652"))
//          .toList();
      setState(() {
        _contacts = contacts;
      });

      // Lazy load thumbnails after rendering initial contacts.
      for (final contact in contacts) {
        ContactsService.getAvatar(contact).then((avatar) {
          if (avatar == null) return; // Don't redraw if no change.
          setState(() => contact.avatar = avatar);
        });
      }
    } else {
      _handleInvalidPermissions(permissionStatus);
    }
  }

  updateContact() async {
    Contact ninja = _contacts.toList().firstWhere((contact) => contact.familyName.startsWith("Ninja"));
    ninja.avatar = null;
    await ContactsService.updateContact(ninja);

    refreshContacts();
  }

  Future<PermissionStatus> _getContactPermission() async {
    PermissionStatus permission = await PermissionHandler().checkPermissionStatus(PermissionGroup.contacts);
    if (permission != PermissionStatus.granted && permission != PermissionStatus.disabled) {
      Map<PermissionGroup, PermissionStatus> permissionStatus = await PermissionHandler().requestPermissions([PermissionGroup.contacts]);
      return permissionStatus[PermissionGroup.contacts] ?? PermissionStatus.unknown;
    } else {
      return permission;
    }
  }

  void _handleInvalidPermissions(PermissionStatus permissionStatus) {
    if (permissionStatus == PermissionStatus.denied) {
      throw new PlatformException(
          code: "PERMISSION_DENIED",
          message: "Access to location data denied",
          details: null);
    } else if (permissionStatus == PermissionStatus.disabled) {
      throw new PlatformException(
          code: "PERMISSION_DISABLED",
          message: "Location data is not available on device",
          details: null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: Icon(Icons.clear,color: Colors.white,), onPressed: (){
          Navigator.of(context).pop();
        }),
        title: Text('Select People '),backgroundColor: Colors.black,),
      body: SafeArea(
        child:Column(
          children: <Widget>[
            Center(
                  child: Padding(
                    padding: const EdgeInsets.only(
                        left: 30.0, right: 30.0, top: 30.0, bottom: 30.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Color(0xffe9e9e9),
                          border: Border.all(
                              color: Color(0xffe9e9e9),
                              width: 1
                          ),
                        borderRadius: BorderRadius.circular(10.0)
                      ),
                      child: TextFormField(
                          controller: searchName,
                          onSaved: (String name) {
                          },

                          validator: (value) {
                            if (value.isEmpty) {
                              return 'Enter phone number';
                            }
                            return null;
                          },
                          style: TextStyle(
                            fontFamily: 'Aileron',
                            color: Color(0xffffffff),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            fontStyle: FontStyle.normal,
                          ),
                          keyboardType: TextInputType.text,
                          decoration: InputDecoration(
                            contentPadding: EdgeInsets.fromLTRB(
                                20.0, 15.0, 20.0, 15.0),
                            enabledBorder: const OutlineInputBorder(
                              borderSide: const BorderSide(
                                  color: Colors.transparent, width: 0.0),
                            ),
                            hintText: 'Type a name',
                            hintStyle: TextStyle(
                              fontFamily: 'Aileron',
                              color: Color(0xff797979),
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              fontStyle: FontStyle.normal,
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.transparent),
                            ),
                          ),
                          onChanged: (value)=>(){

                          },
                          onFieldSubmitted: (value) =>
                              () {
                            print(value);
                          }
                      ),
                    ),
                  ),
            ),
            Expanded(
              child: _contacts != null
                  ? ListView.builder(
                itemCount: _contacts?.length ?? 0,
                itemBuilder: (BuildContext context, int index) {
                  Contact c = _contacts?.elementAt(index);
                  return filter == null ||
                      filter == ""?Column(
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          child: ListTile(
                            onTap: () {
//                Navigator.of(context).push(MaterialPageRoute(
//                    builder: (BuildContext context) =>
//                        ContactDetailsPage(c)));
                            },
                            leading: (c.avatar != null && c.avatar.length > 0)
                                ? CircleAvatar(backgroundImage: MemoryImage(c.avatar))
                                : CircleAvatar(
                                backgroundColor: (index% 2 == 0) ? Color(0xfffad6d6):(index% 3 == 0)?Color(0xffc7ddd1):(index%4==0)?Color(0xffcbd5e1):Color(0xffb5dcea),
                                child: Text(c.initials(),style: TextStyle(color: Colors.black),)),
                            title: Text(c.displayName ?? ""),

                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(0.0),
                        child: Divider(
                          thickness: 0.5,
                        ),
                      )
                    ],
                  )
                  :'${_contacts[index].displayName}'.toLowerCase().contains(filter.toLowerCase())
                  ?Column(
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          child: ListTile(
                            onTap: () {
//                Navigator.of(context).push(MaterialPageRoute(
//                    builder: (BuildContext context) =>
//                        ContactDetailsPage(c)));
                            },
                            leading: (c.avatar != null && c.avatar.length > 0)
                                ? CircleAvatar(backgroundImage: MemoryImage(c.avatar))
                                : CircleAvatar(
                                backgroundColor: (index% 2 == 0) ? Color(0xfffad6d6):(index% 3 == 0)?Color(0xffc7ddd1):(index%4==0)?Color(0xffcbd5e1):Color(0xffb5dcea),
                                child: Text(c.initials(),style: TextStyle(color: Colors.black),)),
                            title: Text(c.displayName ?? ""),

                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(0.0),
                        child: Divider(
                          thickness: 0.5,
                        ),
                      )
                    ],
                  ):new Container();
                },
              )
                  : Center(child: CircularProgressIndicator(),),
            ),
          ],
        )

      ),
    );
  }
}
