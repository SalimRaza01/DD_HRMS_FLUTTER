import 'package:flutter/services.dart';
import 'package:hrms/core/api/api.dart';
import 'package:hrms/core/model/models.dart';
import 'package:hrms/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:hrms/presentation/odoo/create_project.dart';
import 'package:hrms/presentation/odoo/view_projects.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

class OdooDashboard extends StatefulWidget {
  const OdooDashboard({super.key});
  @override
  State<OdooDashboard> createState() => _OdooDashboardState();
}

class _OdooDashboardState extends State<OdooDashboard> {
  late Future<List<OdooProjectList>> _projectsFuture;
  String _selectedText = 'All Task';
  Color? activeColor;
  Color? activeText;

  @override
  void initState() {
    super.initState();
    _projectsFuture = fetchOdooProjects();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
        backgroundColor: AppColor.mainBGColor,
        appBar: AppBar(
          backgroundColor: AppColor.mainThemeColor,
          leading: InkWell(
            onTap: () {
              Navigator.pop(context);
            },
            child: Icon(
              Icons.arrow_back_ios,
              color: Colors.white,
            ),
          ),
          title: Text(
            'DASHBOARD',
    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w400, fontSize: height * 0.02),
          ),
          centerTitle: true,
        ),
        body: SizedBox(
          height: height,
          width: width,
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Project's",
                  style: TextStyle(
                      fontSize: height * 0.018,
                      color: AppColor.mainTextColor,
                      fontWeight: FontWeight.w500),
                ),
                SizedBox(
                  height: height * 0.02,
                ),
                SizedBox(
                  height: height * 0.2,
                  child: FutureBuilder<List<OdooProjectList>>(
                    future: _projectsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      } else if (snapshot.hasData &&
                          snapshot.data!.isNotEmpty) {
                        List<OdooProjectList> items = snapshot.data!;
                                    
                        return ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            OdooProjectList item = items[index];
                                    
                            String formattedDate = item.date_start == "False"
                                ? "No start date"
                                : item.date_start;
                                    
                            return  InkWell(
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context)=> ViewProjects(projectName: item.name, projectID: item.id)));
                              },
                              child: projectCard(
                                height, width, index <= 8 ? 'Project : 0${index + 1}' :'Project : ${index + 1}' , item.name, formattedDate),
                            ); 
                          },
                          separatorBuilder: (BuildContext context, int index) {
                            return SizedBox(
                              height: height * 0.01,
                            );
                          },
                        );
                      } else {
                        return Center(child: Text('No projects found.'));
                      }
                    },
                  ),
                ),
                SizedBox(
                  height: height * 0.02,
                ),
                Text(
                  "Today's Task",
                  style: TextStyle(
                      fontSize: height * 0.018,
                      color: AppColor.mainTextColor,
                      fontWeight: FontWeight.w500),
                ),
                SizedBox(
                  height: height * 0.02,
                ),
                Card(
                  color: Colors.white,
                  elevation: 4,
                  margin: EdgeInsets.all(0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  shadowColor: Colors.black.withOpacity(0.1),
                  child: Padding(
                    padding: EdgeInsets.all(4),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _selectButton('All Task', height, width),
                          _selectButton('Pending', height, width),
                          _selectButton('Completed', height, width),
                        ]),
                  ),
                ),
                SizedBox(
                  height: height * 0.02,
                ),
                Card(
                  color: Colors.white,
                  elevation: 4,
                  margin: EdgeInsets.all(0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  shadowColor: Colors.black.withOpacity(0.1),
                  child: Stack(
                    alignment: AlignmentDirectional.topEnd,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.circle_outlined,
                                  color: Colors.red,
                                ),
                                SizedBox(
                                  width: width * 0.02,
                                ),
                                Text(
                                  'Smart Bolus',
                                  style: TextStyle(
                                      color: AppColor.mainTextColor,
                                      fontSize: height * 0.02,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                              child: Container(
                                width: width,
                                decoration: BoxDecoration(
                                    border: Border.all(
                                        color:
                                            const Color.fromARGB(14, 0, 0, 0)),
                                    color: AppColor.mainBGColor,
                                    borderRadius: BorderRadius.circular(5)),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    'Sandarbh',
                                    style: TextStyle(
                                        color: AppColor.mainTextColor2,
                                        fontSize: height * 0.015,
                                        fontWeight: FontWeight.w400),
                                  ),
                                ),
                              ),
                            ),
                            Text(
                              'Deadline : 12 Jan 2025',
                              style: TextStyle(
                                  color: AppColor.mainTextColor2,
                                  fontSize: height * 0.015,
                                  fontWeight: FontWeight.w400),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.only(
                                topRight: Radius.circular(10),
                                bottomLeft: Radius.circular(10))),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 5.0, horizontal: 30.0),
                          child: Text(
                            'High',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: height * 0.015,
                                fontWeight: FontWeight.w400),
                          ),
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: AppColor.mainThemeColor,
          onPressed: () => showCupertinoModalBottomSheet(
            expand: true,
            context: context,
            barrierColor: const Color.fromARGB(130, 0, 0, 0),
            backgroundColor: Colors.transparent,
            builder: (context) => CreateProject(),
          ),
          label: Text(
            'Create Project',
            style: TextStyle(color: Colors.white),
          ),
        ));
  }

  projectCard(double height, double width, String projectCount,
      String projectName, String createDate) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Card(
        color: Colors.white,
        elevation: 5,
        margin: EdgeInsets.all(0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        shadowColor: Colors.black.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Container(
            height: height * 0.18,
            width: width / 2,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomCenter,
                colors: [
                  AppColor.secondaryThemeColor2,
                  AppColor.primaryThemeColor,
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Image.asset(
                        'assets/image/projectImage.png',
                        height: 40,
                      ),
                      SizedBox(
                        width: width * 0.02,
                      ),
                      Text(
                        projectCount,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: height * 0.02,
                            fontWeight: FontWeight.w400),
                      )
                    ],
                  ),
                  Text(
                    projectName,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: height * 0.02,
                        fontWeight: FontWeight.bold),
                  ),
                  Text(
                    createDate,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: height * 0.015,
                        fontWeight: FontWeight.w400),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _selectButton(String text, double height, double width) {
    Color activeColor;
    Color activeText;

    if (_selectedText == text) {
      activeColor = AppColor.mainThemeColor;
      activeText = Colors.white;
    } else {
      activeColor = Colors.transparent;
      activeText = const Color.fromARGB(141, 0, 0, 0);
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedText = text;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: activeColor,
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: width * 0.05, vertical: 10),
          child: Text(
            text,
            style: TextStyle(
              color: activeText,
              fontSize: height * 0.015,
            ),
          ),
        ),
      ),
    );
  }
}