// ignore_for_file: sort_child_properties_last
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:hrms/core/api/api.dart';
import 'package:hrms/core/model/models.dart';
import 'package:hrms/core/provider/provider.dart';
import 'package:hrms/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'apply_leave.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

class LeaveScreenManager extends StatefulWidget {
  final String empID;
  const LeaveScreenManager(this.empID);

  @override
  State<LeaveScreenManager> createState() => _LeaveScreenState();
}

class _LeaveScreenState extends State<LeaveScreenManager>
    with SingleTickerProviderStateMixin {
  late String documentType;
  bool isDownloading = false;
  late String? empID;
  bool isLoading = true;
  bool switchMode = false;
  int touchedIndex = -1;
  String _selectedText = 'Pending';
  String _selectedCompoffText = 'Pending';
  Color? activeColor;
  Color? activeText;
  String updateUser = 'Leaves';
  late TabController _tabController;
  late Future<List<LeaveHistory>> _myLeaveHistory;
  late Future<List<LeaveRequests>> _teamLeaveRequest;
  late Future<List<CompOffRequest>> _teamCompOffRequest;
  late Future<List<CompOffRequest>> _myCompOffRequest;

  @override
  void initState() {
    _myLeaveHistory = fetchLeaveHistory(_selectedText, widget.empID);
    _teamCompOffRequest = fetchCompOffRequest(_selectedCompoffText);
    _teamLeaveRequest = fetchLeaveRequest(_selectedText);
    _myCompOffRequest = fetchOwnCompOffRequest(_selectedCompoffText);
    _tabController = TabController(vsync: this, length: 2);
    _tabController.addListener(_handleTabSelection);
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  void _handleTabSelection() {
    setState(() {
      switch (_tabController.index) {
        case 0:
          updateUser = switchMode ? 'Team Leave' : 'Leaves';
          _teamLeaveRequest = fetchLeaveRequest(_selectedText);
          _myLeaveHistory = fetchLeaveHistory(_selectedText, widget.empID);
          break;
        case 1:
          updateUser = switchMode ? 'Team Comp-off' : 'Comp-off';
          _teamCompOffRequest = fetchCompOffRequest(_selectedCompoffText);
          _myCompOffRequest = fetchOwnCompOffRequest(_selectedCompoffText);
          break;
      }
    });
  }

  Future<void> _downloadDocument(String url) async {
    final plugin = DeviceInfoPlugin();
    final android = await plugin.androidInfo;
    final status = android.version.sdkInt < 33
        ? await Permission.manageExternalStorage.request()
        : PermissionStatus.granted;
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:
            Text('Storage permission is required to download the document'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    setState(() {
      isDownloading = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Downloading Document'),
        backgroundColor: Colors.blue,
      ),
    );

    try {
      final dio = Dio();
      final response = await dio.get(
        url,
        options: Options(responseType: ResponseType.bytes),
      );
final directory = await getExternalStorageDirectory();
      final fileName = url.split('/').last;
final filePath = '${directory!.path}/$fileName.pdf';


      final file = File(filePath);
      await file.writeAsBytes(response.data);

      setState(() {
        isDownloading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Downloaded to $filePath'),
        backgroundColor: Colors.green,
      ));

      final result = await OpenFile.open(filePath);

      if (result.type != ResultType.done) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to open the file'),
          backgroundColor: Colors.red,
        ));
      }
    } catch (e) {
      print(e);
      setState(() {
        isDownloading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to download the document $e'),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    return switchMode ? teamSection(height, width) : selfSection(height, width);
  }

  selfSection(double height, double width) {
    return SafeArea(
      child: Consumer<LeaveApplied>(builder: (context, value, child) {
        if (value.leaveappied == true) {
          _myLeaveHistory = fetchLeaveHistory(_selectedText, widget.empID);
          _myCompOffRequest = fetchOwnCompOffRequest(_selectedCompoffText);
          Future.delayed(Duration(milliseconds: 1500), () {
            Provider.of<LeaveApplied>(context, listen: false)
                .leaveappiedStatus(false);
          });
        }
        return Scaffold(
            extendBodyBehindAppBar: true,
            backgroundColor: AppColor.mainBGColor,
            body: Stack(
              children: [
                Container(
                  height: height * 0.27,
                  width: width,
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColor.primaryThemeColor,
                          AppColor.secondaryThemeColor2,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                            spreadRadius: 2,
                            blurRadius: 10,
                            color: Colors.black.withOpacity(0.1),
                            offset: Offset(0, 10))
                      ],
                      color: AppColor.mainThemeColor,
                      borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(20),
                          bottomRight: Radius.circular(20))),
                ),
                Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TabBar(
                          dividerColor: Colors.transparent,
                          controller: _tabController,
                          indicatorColor: AppColor.mainFGColor,
                          labelColor: AppColor.mainFGColor,
                          unselectedLabelColor:
                              const Color.fromARGB(206, 255, 255, 255),
                          tabs: [
                            Tab(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.person),
                                  Text('My Leaves')
                                ],
                              ),
                              // text: 'Self',
                            ),
                            Tab(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.person),
                                  Text('My Comp-off')
                                ],
                              ),
                              // text: 'Self',
                            ),
                          ]),
                      SizedBox(
                        height: height * 0.015,
                      ),
                      Expanded(
                        child:
                            TabBarView(controller: _tabController, children: [
                          Column(
                            children: [
                              Card(
                                color: AppColor.mainFGColor,
                                elevation: 4,
                                margin: EdgeInsets.all(0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                shadowColor: Colors.black.withOpacity(0.1),
                                child: Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: FutureBuilder<LeaveBalance>(
                                      future: fetchLeaves(widget.empID),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState ==
                                            ConnectionState.waiting) {
                                          return Center(
                                            child: LoadingAnimationWidget
                                                .threeArchedCircle(
                                              color: AppColor.mainTextColor2,
                                              size: height * 0.03,
                                            ),
                                          );
                                        } else if (snapshot.hasError) {
                                          return Center(
                                              child: Text('No Data Found'));
                                        } else if (snapshot.hasData) {
                                          final leave = snapshot.data!;

                                          return Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              leaveWidget(height, width,
                                                  'Casual', leave.casualLeave),
                                              leaveWidget(
                                                  height,
                                                  width,
                                                  'Medical',
                                                  leave.medicalLeave),
                                              leaveWidget(height, width,
                                                  'Earned', leave.earnedLeave),
                                            ],
                                          );
                                        } else {
                                          return Center(
                                              child: Text('No Data Found'));
                                        }
                                      }),
                                ),
                              ),
                              SizedBox(
                                height: height * 0.02,
                              ),
                              Card(
                                color: AppColor.mainFGColor,
                                elevation: 4,
                                margin: EdgeInsets.all(0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                shadowColor: Colors.black.withOpacity(0.1),
                                child: Padding(
                                  padding: EdgeInsets.all(4),
                                  child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        _selectButton('Pending', height, width),
                                        _selectButton(
                                            'Approved', height, width),
                                        _selectButton(
                                            'Rejected', height, width),
                                      ]),
                                ),
                              ),
                              SizedBox(
                                height: height * 0.015,
                              ),
                              Expanded(
                                child: FutureBuilder<List<LeaveHistory>>(
                                    future: _myLeaveHistory,
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return Center(
                                          child: LoadingAnimationWidget
                                              .threeArchedCircle(
                                            color: AppColor.mainTextColor2,
                                            size: height * 0.03,
                                          ),
                                        );
                                      } else if (snapshot.hasError) {
                                        return Center(
                                          child: Card(
                                            color: AppColor.mainFGColor,
                                            elevation: 4,
                                            margin: EdgeInsets.all(0),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Text('No History Found'),
                                            ),
                                            shadowColor:
                                                Colors.black.withOpacity(0.1),
                                          ),
                                        );
                                      } else if (!snapshot.hasData ||
                                          snapshot.data!.isEmpty) {
                                        return Center(
                                            child: Text('No History Found'));
                                      } else {
                                        List<LeaveHistory> items =
                                            snapshot.data!;

                                        return ListView.separated(
                                          itemCount: items.length,
                                          itemBuilder: (context, index) {
                                            final leave = items[index];
                                            final startDate = DateTime.parse(
                                                leave.leaveStartDate);
                                            final endDate = DateTime.parse(
                                                leave.leaveEndDate);

                                            return Card(
                                              color: AppColor.mainFGColor,
                                              elevation: 8,
                                              margin: EdgeInsets.all(0),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              shadowColor:
                                                  Colors.black.withOpacity(0.2),
                                              child: Stack(
                                                alignment:
                                                    AlignmentDirectional.topEnd,
                                                children: [
                                                  Padding(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 14,
                                                        vertical: 8),
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceBetween,
                                                          children: [
                                                            Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                Text(
                                                                  leave.leaveType ==
                                                                          'earnedLeave'
                                                                      ? leave.totalDays ==
                                                                              '1'
                                                                          ? 'Earned - Full Day Application'
                                                                          : leave.totalDays ==
                                                                                  '0.5'
                                                                              ? 'Earned - Half-Day Application'
                                                                              : 'Earned - ${leave.totalDays} Days Application'
                                                                      : leave.leaveType ==
                                                                              'medicalLeave'
                                                                          ? leave.totalDays == '1'
                                                                              ? 'Medical - Full Day Application'
                                                                              : leave.totalDays == '0.5'
                                                                                  ? 'Medical - Half-Day Application'
                                                                                  : 'Medical - ${leave.totalDays} Days Application'
                                                                          : leave.leaveType == 'casualLeave'
                                                                              ? leave.totalDays == '1'
                                                                                  ? 'Casual - Full Day Application'
                                                                                  : leave.totalDays == '0.5'
                                                                                      ? 'Casual - Half-Day Application'
                                                                                      : 'Casual - ${leave.totalDays} Days Application'
                                                                              : leave.leaveType == 'paternityLeave'
                                                                                  ? leave.totalDays == '1'
                                                                                      ? 'Paternity - Full Day Application'
                                                                                      : leave.totalDays == '0.5'
                                                                                          ? 'Paternity - Half-Day Application'
                                                                                          : 'Paternity - ${leave.totalDays} Days Application'
                                                                                  : leave.leaveType == 'maternityLeave'
                                                                                      ? leave.totalDays == '1'
                                                                                          ? 'Maternity - Full Day Application'
                                                                                          : leave.totalDays == '0.5'
                                                                                              ? 'Maternity - Half-Day Application'
                                                                                              : 'Maternity - ${leave.totalDays} Days Application'
                                                                                      : leave.leaveType == 'regularized'
                                                                                          ? 'Regularization'
                                                                                          : leave.leaveType == 'shortLeave'
                                                                                              ? 'Short-Leave'
                                                                                              : leave.leaveType,
                                                                  style:
                                                                      TextStyle(
                                                                    fontSize:
                                                                        height *
                                                                            0.013,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                    color: AppColor
                                                                        .mainThemeColor,
                                                                  ),
                                                                ),
                                                                Text(
                                                                  leave.totalDays ==
                                                                              '1' ||
                                                                          leave.totalDays ==
                                                                              '0.5'
                                                                      ? DateFormat(
                                                                              'EEE, dd MMM')
                                                                          .format(
                                                                              startDate)
                                                                      : '${DateFormat('EEE, dd MMM').format(startDate)} - ${DateFormat('EEE, dd MMM').format(endDate)}',
                                                                  style:
                                                                      TextStyle(
                                                                    fontSize:
                                                                        height *
                                                                            0.015,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    color: AppColor
                                                                        .mainTextColor,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ],
                                                        ),
                                                        SizedBox(
                                                            height:
                                                                height * 0.015),
                                                        Container(
                                                          width: width,
                                                          decoration:
                                                              BoxDecoration(
                                                            color: AppColor
                                                                .mainBGColor,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        7),
                                                            // boxShadow: [
                                                            //   BoxShadow(
                                                            //     color: Colors.black12,
                                                            //     blurRadius: 4,
                                                            //     offset: Offset(0, 2),
                                                            //   ),
                                                            // ],
                                                          ),
                                                          child: Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(8),
                                                            child: Text(
                                                              leave.reason,
                                                              style: TextStyle(
                                                                fontSize:
                                                                    height *
                                                                        0.014,
                                                                color: Colors
                                                                    .black54,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w400,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                        Visibility(
                                                          visible: leave
                                                              .location!
                                                              .isNotEmpty,
                                                          child: Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .only(
                                                                    top: 12),
                                                            child: InkWell(
                                                              onTap: () {
                                                                _downloadDocument(
                                                                    leave
                                                                        .location!);
                                                              },
                                                              child: Container(
                                                                width: width,
                                                                decoration:
                                                                    BoxDecoration(
                                                                  border: Border.all(
                                                                      color: AppColor
                                                                          .mainBGColor,
                                                                      width: 2),
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              12),
                                                                  color: Colors
                                                                      .white,
                                                                ),
                                                                child: Padding(
                                                                  padding:
                                                                      const EdgeInsets
                                                                          .all(
                                                                          8.0),
                                                                  child: Row(
                                                                    children: [
                                                                      Icon(
                                                                        Icons
                                                                            .file_copy_rounded,
                                                                        color: Colors
                                                                            .blue,
                                                                        size: height *
                                                                            0.013,
                                                                      ),
                                                                      SizedBox(
                                                                          width:
                                                                              width * 0.03),
                                                                      Text(
                                                                        'View Prescription',
                                                                        style:
                                                                            TextStyle(
                                                                          color:
                                                                              AppColor.mainTextColor2,
                                                                          fontSize:
                                                                              height * 0.012,
                                                                          fontWeight:
                                                                              FontWeight.w500,
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                        SizedBox(
                                                            height:
                                                                height * 0.005),
                                                      ],
                                                    ),
                                                  ),
                                                  Container(
                                                    decoration: BoxDecoration(
                                                        color: leave.status ==
                                                                'Pending'
                                                            ? Colors.amber
                                                            : leave.status ==
                                                                    'Approved'
                                                                ? Colors.green
                                                                : Colors.red,
                                                        borderRadius:
                                                            BorderRadius.only(
                                                                topRight: Radius
                                                                    .circular(
                                                                        10),
                                                                bottomLeft: Radius
                                                                    .circular(
                                                                        20))),
                                                    child: Padding(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          vertical: 0,
                                                          horizontal: 20),
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(7.0),
                                                        child: Text(
                                                          leave.status,
                                                          style: TextStyle(
                                                              fontSize: height *
                                                                  0.012,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w400,
                                                              color: leave.status ==
                                                                      'Pending'
                                                                  ? Colors.black
                                                                  : Colors
                                                                      .white),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                          separatorBuilder: (context, index) =>
                                              SizedBox(height: 10),
                                        );
                                      }
                                    }),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              Card(
                                color: AppColor.mainFGColor,
                                elevation: 4,
                                margin: EdgeInsets.all(0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                shadowColor: Colors.black.withOpacity(0.1),
                                child: Padding(
                                  padding: EdgeInsets.all(4),
                                  child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        _compoffSelectedButton(
                                            'Pending', height, width),
                                        _compoffSelectedButton(
                                            'Approved', height, width),
                                        _compoffSelectedButton(
                                            'Rejected', height, width),
                                      ]),
                                ),
                              ),
                              SizedBox(
                                height: height * 0.015,
                              ),
                              Expanded(
                                child: FutureBuilder<List<CompOffRequest>>(
                                    future: _myCompOffRequest,
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return Center(
                                          child: LoadingAnimationWidget
                                              .threeArchedCircle(
                                            color: AppColor.mainTextColor2,
                                            size: height * 0.03,
                                          ),
                                        );
                                      } else if (snapshot.hasError) {
                                        return Center(
                                          child: Card(
                                            color: AppColor.mainFGColor,
                                            elevation: 4,
                                            margin: EdgeInsets.all(0),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Text(
                                                'No Comp-Off Request Found',
                                                style: TextStyle(
                                                    fontSize: height * 0.014),
                                              ),
                                            ),
                                            shadowColor:
                                                Colors.black.withOpacity(0.1),
                                          ),
                                        );
                                      } else if (!snapshot.hasData ||
                                          snapshot.data!.isEmpty) {
                                        return Center(
                                          child: Card(
                                            color: AppColor.mainFGColor,
                                            elevation: 4,
                                            margin: EdgeInsets.all(0),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Text(
                                                'No Comp-Off Request Found',
                                                style: TextStyle(
                                                    fontSize: height * 0.014),
                                              ),
                                            ),
                                            shadowColor:
                                                Colors.black.withOpacity(0.1),
                                          ),
                                        );
                                      } else {
                                        List<CompOffRequest> items =
                                            snapshot.data!;

                                        return ListView.separated(
                                          itemCount: items.length,
                                          itemBuilder: (context, index) {
                                            final leave = items[index];
                                            // final startDate = DateTime.parse(leave.appliedDate);

                                            return Card(
                                              color: AppColor.mainFGColor,
                                              elevation: 8,
                                              margin: EdgeInsets.all(0),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              shadowColor:
                                                  Colors.black.withOpacity(0.2),
                                              child: Stack(
                                                alignment:
                                                    AlignmentDirectional.topEnd,
                                                children: [
                                                  Padding(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 14,
                                                        vertical: 8),
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceBetween,
                                                          children: [
                                                            Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                Text(
                                                                  'Comp-Off Request (${leave.totalDays})',
                                                                  style:
                                                                      TextStyle(
                                                                    fontSize:
                                                                        height *
                                                                            0.013,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                    color: AppColor
                                                                        .mainThemeColor,
                                                                  ),
                                                                ),
                                                                Text(
                                                                  leave
                                                                      .compOffDate,
                                                                  style:
                                                                      TextStyle(
                                                                    fontSize:
                                                                        height *
                                                                            0.015,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    color: AppColor
                                                                        .mainTextColor,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ],
                                                        ),
                                                        SizedBox(
                                                            height:
                                                                height * 0.012),
                                                        Container(
                                                          width: width,
                                                          decoration:
                                                              BoxDecoration(
                                                            color: AppColor
                                                                .mainBGColor,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        7),
                                                            // boxShadow: [
                                                            //   BoxShadow(
                                                            //     color: Colors.black12,
                                                            //     blurRadius: 4,
                                                            //     offset: Offset(0, 2),
                                                            //   ),
                                                            // ],
                                                          ),
                                                          child: Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(8),
                                                            child: Text(
                                                              leave.reason,
                                                              style: TextStyle(
                                                                fontSize:
                                                                    height *
                                                                        0.014,
                                                                color: Colors
                                                                    .black54,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w400,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                        Visibility(
                                                          visible:
                                                              leave.status ==
                                                                  'Pending',
                                                          child: Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .only(
                                                                    top: 15),
                                                            child: Center(
                                                              child:
                                                                  GestureDetector(
                                                                onTap:
                                                                    () async {
                                                                  await ownCompOffActionDelete(
                                                                      context,
                                                                      leave.id);
                                                                  setState(() {
                                                                    _myCompOffRequest =
                                                                        fetchOwnCompOffRequest(
                                                                            _selectedCompoffText);
                                                                  });
                                                                },
                                                                child:
                                                                    Container(
                                                                  decoration: BoxDecoration(
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              8),
                                                                      color: Colors
                                                                          .redAccent),
                                                                  child:
                                                                      Padding(
                                                                    padding: EdgeInsets.symmetric(
                                                                        horizontal:
                                                                            width /
                                                                                9,
                                                                        vertical:
                                                                            8),
                                                                    child: Text(
                                                                      'Delete Request',
                                                                      style:
                                                                          TextStyle(
                                                                        color: Colors
                                                                            .white,
                                                                        fontSize:
                                                                            height *
                                                                                0.012,
                                                                        fontWeight:
                                                                            FontWeight.w500,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                        SizedBox(
                                                            height:
                                                                height * 0.005),
                                                      ],
                                                    ),
                                                  ),
                                                  Container(
                                                    decoration: BoxDecoration(
                                                        color: leave.status ==
                                                                'Pending'
                                                            ? Colors.amber
                                                            : leave.status ==
                                                                    'Approved'
                                                                ? Colors.green
                                                                : Colors.red,
                                                        borderRadius:
                                                            BorderRadius.only(
                                                                topRight: Radius
                                                                    .circular(
                                                                        10),
                                                                bottomLeft: Radius
                                                                    .circular(
                                                                        20))),
                                                    child: Padding(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          vertical: 0,
                                                          horizontal: 20),
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(7.0),
                                                        child: Text(
                                                          leave.status,
                                                          style: TextStyle(
                                                              fontSize: height *
                                                                  0.012,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w400,
                                                              color: leave.status ==
                                                                      'Pending'
                                                                  ? Colors.black
                                                                  : Colors
                                                                      .white),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                          separatorBuilder: (context, index) =>
                                              SizedBox(height: 10),
                                        );
                                      }
                                    }),
                              ),
                            ],
                          ),
                        ]),
                      )
                    ],
                  ),
                ),
              ],
            ),
            floatingActionButton: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FloatingActionButton.extended(
                    heroTag: 'btn1',
                    backgroundColor: AppColor.mainThemeColor,
                    onPressed: () {
                      setState(() {
                        switchMode = !switchMode;
                        _teamLeaveRequest = fetchLeaveRequest(_selectedText);
                   _teamCompOffRequest = fetchCompOffRequest(_selectedCompoffText);
                      });
                    },
                    label: Icon(
                      CupertinoIcons.person_2_fill,
                      color: Colors.white,
                    )),
                SizedBox(
                  height: height * 0.015,
                ),
                FloatingActionButton.extended(
                  heroTag: 'btn2',
                  backgroundColor: AppColor.mainThemeColor,
                  onPressed: () => showCupertinoModalBottomSheet(
                    expand: true,
                    context: context,
                    barrierColor: const Color.fromARGB(130, 0, 0, 0),
                    backgroundColor: Colors.transparent,
                    builder: (context) => ApplyLeave(),
                  ),
                  label: Text(
                    'Apply Leave',
                    style: TextStyle(color: AppColor.mainFGColor),
                  ),
                ),
              ],
            ));
      }),
    );
  }

  teamSection(double height, double width) {
    return SafeArea(
      child: Consumer<LeaveApplied>(builder: (context, value, child) {
        if (value.leaveappied == true) {
          _teamLeaveRequest = fetchLeaveRequest(_selectedText);
          _teamCompOffRequest = fetchCompOffRequest(_selectedCompoffText);
          Future.delayed(Duration(milliseconds: 1500), () {
            Provider.of<LeaveApplied>(context, listen: false)
                .leaveappiedStatus(false);
          });
        }
        return Scaffold(
            extendBodyBehindAppBar: true,
            backgroundColor: AppColor.mainBGColor,
            body: Stack(
              children: [
                Container(
                  height: height * 0.27,
                  width: width,
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColor.primaryThemeColor,
                          AppColor.secondaryThemeColor2,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                            spreadRadius: 2,
                            blurRadius: 10,
                            color: Colors.black.withOpacity(0.1),
                            offset: Offset(0, 10))
                      ],
                      color: AppColor.mainThemeColor,
                      borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(20),
                          bottomRight: Radius.circular(20))),
                ),
                Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TabBar(
                          dividerColor: Colors.transparent,
                          controller: _tabController,
                          indicatorColor: AppColor.mainFGColor,
                          labelColor: AppColor.mainFGColor,
                          unselectedLabelColor:
                              const Color.fromARGB(206, 255, 255, 255),
                          tabs: [
                            Tab(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.person),
                                  Text('Team Leave')
                                ],
                              ),
                              // text: 'Self',
                            ),
                            Tab(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.person),
                                  Text('Team Comp-off')
                                ],
                              ),
                              // text: 'Self',
                            ),
                          ]),
                      SizedBox(
                        height: height * 0.015,
                      ),
                      Expanded(
                        child: TabBarView(
                            controller: _tabController,
                            children: [
                              Column(
                                children: [
                                   Card(
                                color: AppColor.mainFGColor,
                                elevation: 4,
                                margin: EdgeInsets.all(0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                shadowColor: Colors.black.withOpacity(0.1),
                                child: Padding(
                                  padding: EdgeInsets.all(4),
                                  child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        _leaveFilterBTNTeam('Pending', height, width),
                                        _leaveFilterBTNTeam(
                                            'Approved', height, width),
                                        _leaveFilterBTNTeam(
                                            'Rejected', height, width),
                                      ]),
                                ),
                              ),
                              SizedBox(
                                height: height * 0.015,
                              ),
                                  Expanded(
                                      child: FutureBuilder<List<LeaveRequests>>(
                                          future: _teamLeaveRequest,
                                          builder: (context, snapshot) {
                                            if (snapshot.connectionState ==
                                                ConnectionState.waiting) {
                                              return Center(
                                                child: LoadingAnimationWidget
                                                    .threeArchedCircle(
                                                  color:
                                                      AppColor.mainTextColor2,
                                                  size: height * 0.03,
                                                ),
                                              );
                                            } else if (snapshot.hasError) {
                                              return Center(
                                                child: Card(
                                                  color: AppColor.mainFGColor,
                                                  elevation: 4,
                                                  margin: EdgeInsets.all(0),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                  ),
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            8.0),
                                                    child: Text(
                                                        'No Leave Request Found'),
                                                  ),
                                                  shadowColor: Colors.black
                                                      .withOpacity(0.1),
                                                ),
                                              );
                                            } else if (!snapshot.hasData ||
                                                snapshot.data!.isEmpty) {
                                              return Center(
                                                  child: Text(
                                                      'No Leave Request Found'));
                                            } else {
                                              List<LeaveRequests> items =
                                                  snapshot.data!;

                                              return ListView.separated(
                                                itemCount: items.length,
                                                itemBuilder: (context, index) {
                                                  final leave = items[index];
                                                  final startDate =
                                                      DateTime.parse(
                                                          leave.leaveStartDate);
                                                  final endDate =
                                                      DateTime.parse(
                                                          leave.leaveEndDate);
                                                  print(leave.location);
                                                  return Card(
                                                    color: AppColor.mainFGColor,
                                                    elevation: 8,
                                                    margin: EdgeInsets.all(0),
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10),
                                                    ),
                                                    shadowColor: Colors.black
                                                        .withOpacity(0.2),
                                                    child: Stack(
                                                      alignment:
                                                          AlignmentDirectional
                                                              .topEnd,
                                                      children: [
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  horizontal:
                                                                      14,
                                                                  vertical: 8),
                                                          child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Row(
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .spaceBetween,
                                                                children: [
                                                                  Column(
                                                                    crossAxisAlignment:
                                                                        CrossAxisAlignment
                                                                            .start,
                                                                    children: [
                                                                      Text(
                                                                        leave
                                                                            .employeeName,
                                                                        style:
                                                                            TextStyle(
                                                                          fontSize:
                                                                              height * 0.016,
                                                                          color:
                                                                              AppColor.mainTextColor,
                                                                          fontWeight:
                                                                              FontWeight.bold,
                                                                        ),
                                                                      ),
                                                                      Text(
                                                                        leave.leaveType ==
                                                                                'earnedLeave'
                                                                            ? leave.totalDays == '1'
                                                                                ? 'Earned - Full Day Application'
                                                                                : leave.totalDays == '0.5'
                                                                                    ? 'Earned - Half-Day Application'
                                                                                    : 'Earned - ${leave.totalDays} Days Application'
                                                                            : leave.leaveType == 'medicalLeave'
                                                                                ? leave.totalDays == '1'
                                                                                    ? 'Medical - Full Day Application'
                                                                                    : leave.totalDays == '0.5'
                                                                                        ? 'Medical - Half-Day Application'
                                                                                        : 'Medical - ${leave.totalDays} Days Application'
                                                                                : leave.leaveType == 'casualLeave'
                                                                                    ? leave.totalDays == '1'
                                                                                        ? 'Casual - Full Day Application'
                                                                                        : leave.totalDays == '0.5'
                                                                                            ? 'Casual - Half-Day Application'
                                                                                            : 'Casual - ${leave.totalDays} Days Application'
                                                                                    : leave.leaveType == 'paternityLeave'
                                                                                        ? leave.totalDays == '1'
                                                                                            ? 'Paternity - Full Day Application'
                                                                                            : leave.totalDays == '0.5'
                                                                                                ? 'Paternity - Half-Day Application'
                                                                                                : 'Paternity - ${leave.totalDays} Days Application'
                                                                                        : leave.leaveType == 'maternityLeave'
                                                                                            ? leave.totalDays == '1'
                                                                                                ? 'Maternity - Full Day Application'
                                                                                                : leave.totalDays == '0.5'
                                                                                                    ? 'Maternity - Half-Day Application'
                                                                                                    : 'Maternity - ${leave.totalDays} Days Application'
                                                                                            : leave.leaveType == 'regularized'
                                                                                                ? 'Regularization'
                                                                                                : leave.leaveType == 'shortLeave'
                                                                                                    ? 'Short-Leave'
                                                                                                    : leave.leaveType,
                                                                        style:
                                                                            TextStyle(
                                                                          fontSize:
                                                                              height * 0.012,
                                                                          fontWeight:
                                                                              FontWeight.w600,
                                                                          color:
                                                                              AppColor.mainThemeColor,
                                                                        ),
                                                                      ),
                                                                      Text(
                                                                        leave.totalDays == '1' ||
                                                                                leave.totalDays == '0.5'
                                                                            ? DateFormat('EEE, dd MMM').format(startDate)
                                                                            : '${DateFormat('EEE, dd MMM').format(startDate)} - ${DateFormat('EEE, dd MMM').format(endDate)}',
                                                                        style:
                                                                            TextStyle(
                                                                          fontSize:
                                                                              height * 0.012,
                                                                          fontWeight:
                                                                              FontWeight.bold,
                                                                          color:
                                                                              AppColor.mainTextColor,
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ],
                                                              ),
                                                              SizedBox(
                                                                  height:
                                                                      height *
                                                                          0.015),
                                                              Container(
                                                                width: width,
                                                                decoration:
                                                                    BoxDecoration(
                                                                  color: AppColor
                                                                      .mainBGColor,
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              7),
                                                                  // boxShadow: [
                                                                  //   BoxShadow(
                                                                  //     color: Colors.black12,
                                                                  //     blurRadius: 4,
                                                                  //     offset: Offset(0, 2),
                                                                  //   ),
                                                                  // ],
                                                                ),
                                                                child: Padding(
                                                                  padding:
                                                                      const EdgeInsets
                                                                          .all(
                                                                          8),
                                                                  child: Text(
                                                                    leave
                                                                        .reason,
                                                                    style:
                                                                        TextStyle(
                                                                      fontSize:
                                                                          height *
                                                                              0.014,
                                                                      color: Colors
                                                                          .black54,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w400,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                              Visibility(
                                                                visible: leave
                                                                    .location
                                                                    .isNotEmpty,
                                                                child: Padding(
                                                                  padding:
                                                                      const EdgeInsets
                                                                          .only(
                                                                          top:
                                                                              12),
                                                                  child:
                                                                      InkWell(
                                                                    onTap: () {
                                                                      _downloadDocument(
                                                                          leave
                                                                              .location);
                                                                    },
                                                                    child:
                                                                        Container(
                                                                      width:
                                                                          width,
                                                                      decoration:
                                                                          BoxDecoration(
                                                                        border: Border.all(
                                                                            color:
                                                                                AppColor.mainBGColor,
                                                                            width: 2),
                                                                        borderRadius:
                                                                            BorderRadius.circular(12),
                                                                        color: Colors
                                                                            .white,
                                                                      ),
                                                                      child:
                                                                          Padding(
                                                                        padding: const EdgeInsets
                                                                            .all(
                                                                            8.0),
                                                                        child:
                                                                            Row(
                                                                          children: [
                                                                            Icon(
                                                                              Icons.file_copy_rounded,
                                                                              color: Colors.blue,
                                                                              size: height * 0.013,
                                                                            ),
                                                                            SizedBox(width: width * 0.03),
                                                                            Text(
                                                                              'View Prescription',
                                                                              style: TextStyle(
                                                                                color: AppColor.mainTextColor2,
                                                                                fontSize: height * 0.012,
                                                                                fontWeight: FontWeight.w500,
                                                                              ),
                                                                            ),
                                                                          ],
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                              Visibility(
                                                                visible: leave
                                                                        .status ==
                                                                    'Pending',
                                                                child: Padding(
                                                                  padding:
                                                                      const EdgeInsets
                                                                          .only(
                                                                          top:
                                                                              18),
                                                                  child: Row(
                                                                    mainAxisAlignment:
                                                                        MainAxisAlignment
                                                                            .spaceBetween,
                                                                    children: [
                                                                      // Accept Button
                                                                      GestureDetector(
                                                                        onTap:
                                                                            () async {
                                                                          await leaveAction(
                                                                              context,
                                                                              'Approved',
                                                                              leave.id);
                                                                          setState(
                                                                              () {
                                                                            _teamLeaveRequest =
                                                                                fetchLeaveRequest(_selectedText);
                                                                          });
                                                                        },
                                                                        child:
                                                                            Container(
                                                                          decoration:
                                                                              BoxDecoration(
                                                                            borderRadius:
                                                                                BorderRadius.circular(8),
                                                                            color: const Color.fromARGB(
                                                                                126,
                                                                                20,
                                                                                183,
                                                                                25),
                                                                          ),
                                                                          child:
                                                                              Padding(
                                                                            padding:
                                                                                EdgeInsets.symmetric(horizontal: width / 9, vertical: 8),
                                                                            child:
                                                                                Text(
                                                                              'Accept',
                                                                              style: TextStyle(
                                                                                color: AppColor.mainTextColor,
                                                                                fontSize: height * 0.012,
                                                                                fontWeight: FontWeight.w500,
                                                                              ),
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ),

                                                                      GestureDetector(
                                                                        onTap:
                                                                            () async {
                                                                          await leaveAction(
                                                                              context,
                                                                              'Rejected',
                                                                              leave.id);
                                                                          setState(
                                                                              () {
                                                                            _teamLeaveRequest =
                                                                                fetchLeaveRequest(_selectedText);
                                                                          });
                                                                        },
                                                                        child:
                                                                            Container(
                                                                          decoration: BoxDecoration(
                                                                              borderRadius: BorderRadius.circular(8),
                                                                              color: AppColor.mainBGColor),
                                                                          child:
                                                                              Padding(
                                                                            padding:
                                                                                EdgeInsets.symmetric(horizontal: width / 9, vertical: 8),
                                                                            child:
                                                                                Text(
                                                                              'Decline',
                                                                              style: TextStyle(
                                                                                color: AppColor.mainTextColor,
                                                                                fontSize: height * 0.012,
                                                                                fontWeight: FontWeight.w500,
                                                                              ),
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              ),
                                                              SizedBox(
                                                                  height:
                                                                      height *
                                                                          0.005),
                                                            ],
                                                          ),
                                                        ),
                                                        Container(
                                                          decoration:
                                                              BoxDecoration(
                                                                  color: leave.status ==
                                                                          'Pending'
                                                                      ? Colors
                                                                          .amber
                                                                      : leave.status ==
                                                                              'Approved'
                                                                          ? Colors
                                                                              .green
                                                                          : Colors
                                                                              .red,
                                                                  borderRadius: BorderRadius.only(
                                                                      topRight:
                                                                          Radius.circular(
                                                                              10),
                                                                      bottomLeft:
                                                                          Radius.circular(
                                                                              20))),
                                                          child: Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                                    vertical: 0,
                                                                    horizontal:
                                                                        20),
                                                            child: Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .all(7.0),
                                                              child: Text(
                                                                leave.status,
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        height *
                                                                            0.012,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w400,
                                                                    color: leave.status ==
                                                                            'Pending'
                                                                        ? Colors
                                                                            .black
                                                                        : Colors
                                                                            .white),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                },
                                                separatorBuilder:
                                                    (context, index) =>
                                                        SizedBox(height: 10),
                                              );
                                            }
                                          })),
                                ],
                              ),
                              Column(
                                children: [
                                   Card(
                                color: AppColor.mainFGColor,
                                elevation: 4,
                                margin: EdgeInsets.all(0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                shadowColor: Colors.black.withOpacity(0.1),
                                child: Padding(
                                  padding: EdgeInsets.all(4),
                                  child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        _compoffFilterBTNTeam(
                                            'Pending', height, width),
                                        _compoffFilterBTNTeam(
                                            'Approved', height, width),
                                        _compoffFilterBTNTeam(
                                            'Rejected', height, width),
                                      ]),
                                ),
                              ),
                              SizedBox(
                                height: height * 0.015,
                              ),
                                  Expanded(
                                    child: FutureBuilder<List<CompOffRequest>>(
                                        future: _teamCompOffRequest,
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return Center(
                                              child: LoadingAnimationWidget
                                                  .threeArchedCircle(
                                                color: AppColor.mainTextColor2,
                                                size: height * 0.03,
                                              ),
                                            );
                                          } else if (snapshot.hasError) {
                                            return Center(
                                              child: Card(
                                                color: AppColor.mainFGColor,
                                                elevation: 4,
                                                margin: EdgeInsets.all(0),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  child: Text(
                                                      'No Comp-Off Request Found'),
                                                ),
                                                shadowColor: Colors.black
                                                    .withOpacity(0.1),
                                              ),
                                            );
                                          } else if (!snapshot.hasData ||
                                              snapshot.data!.isEmpty) {
                                            return Center(
                                                child: Text(
                                                    'No Comp-Off Request Found'));
                                          } else {
                                            List<CompOffRequest> items =
                                                snapshot.data!;

                                            return ListView.separated(
                                              itemCount: items.length,
                                              itemBuilder: (context, index) {
                                                final leave = items[index];
                                                // final startDate = DateTime.parse(leave.appliedDate);

                                                return Card(
                                                  color: AppColor.mainFGColor,
                                                  elevation: 8,
                                                  margin: EdgeInsets.all(0),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                  ),
                                                  shadowColor: Colors.black
                                                      .withOpacity(0.2),
                                                  child: Stack(
                                                    alignment:
                                                        AlignmentDirectional
                                                            .topEnd,
                                                    children: [
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal: 14,
                                                                vertical: 8),
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Row(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .spaceBetween,
                                                              children: [
                                                                Column(
                                                                  crossAxisAlignment:
                                                                      CrossAxisAlignment
                                                                          .start,
                                                                  children: [
                                                                    Text(
                                                                      leave
                                                                          .employeeName,
                                                                      style:
                                                                          TextStyle(
                                                                        fontSize:
                                                                            height *
                                                                                0.016,
                                                                        color: AppColor
                                                                            .mainTextColor,
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                      ),
                                                                    ),
                                                                    Text(
                                                                      'Comp-Off Request (${leave.totalDays})',
                                                                      style:
                                                                          TextStyle(
                                                                        fontSize:
                                                                            height *
                                                                                0.012,
                                                                        fontWeight:
                                                                            FontWeight.w600,
                                                                        color: AppColor
                                                                            .mainThemeColor,
                                                                      ),
                                                                    ),
                                                                    Text(
                                                                      leave
                                                                          .compOffDate,

                                                                      // leave.totalDays == '1' ||
                                                                      //         leave.totalDays == '0.5'
                                                                      //     ? DateFormat('EEE, dd MMM')
                                                                      //         .format(startDate)
                                                                      //     : '${DateFormat('EEE, dd MMM').format(startDate)} - ${DateFormat('EEE, dd MMM').format(endDate)}',
                                                                      style:
                                                                          TextStyle(
                                                                        fontSize:
                                                                            height *
                                                                                0.012,
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                        color: AppColor
                                                                            .mainTextColor,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ],
                                                            ),
                                                            SizedBox(
                                                                height: height *
                                                                    0.015),
                                                            Container(
                                                              width: width,
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: AppColor
                                                                    .mainBGColor,
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            7),
                                                                // boxShadow: [
                                                                //   BoxShadow(
                                                                //     color: Colors.black12,
                                                                //     blurRadius: 4,
                                                                //     offset: Offset(0, 2),
                                                                //   ),
                                                                // ],
                                                              ),
                                                              child: Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .all(8),
                                                                child: Text(
                                                                  leave.reason,
                                                                  style:
                                                                      TextStyle(
                                                                    fontSize:
                                                                        height *
                                                                            0.014,
                                                                    color: Colors
                                                                        .black54,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w400,
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                            // Visibility(
                                                            //   visible: leave.location.isNotEmpty,
                                                            //   child: Padding(
                                                            //     padding: const EdgeInsets.only(top: 12),
                                                            //     child: Container(
                                                            //       width: width,
                                                            //       decoration: BoxDecoration(
                                                            //         border: Border.all(
                                                            //             color: AppColor.mainBGColor,
                                                            //             width: 2),
                                                            //         borderRadius:
                                                            //             BorderRadius.circular(12),
                                                            //         color: Colors.white,
                                                            //       ),
                                                            //       child: Padding(
                                                            //         padding: const EdgeInsets.all(8.0),
                                                            //         child: Row(
                                                            //           children: [
                                                            //             Icon(
                                                            //               Icons.file_copy_rounded,
                                                            //               color: Colors.blue,
                                                            //               size: height * 0.013,
                                                            //             ),
                                                            //             SizedBox(width: width * 0.03),
                                                            //             Text(
                                                            //               'IMG_45544871.JPG',
                                                            //               style: TextStyle(
                                                            //                 color:
                                                            //                     AppColor.mainTextColor2,
                                                            //                 fontSize: height * 0.012,
                                                            //                 fontWeight: FontWeight.w500,
                                                            //               ),
                                                            //             ),
                                                            //           ],
                                                            //         ),
                                                            //       ),
                                                            //     ),
                                                            //   ),
                                                            // ),
                                                            Visibility(
                                                              visible: leave
                                                                      .status ==
                                                                  'Pending',
                                                              child: Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .only(
                                                                        top:
                                                                            18),
                                                                child: Row(
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .spaceBetween,
                                                                  children: [
                                                                    // Accept Button
                                                                    GestureDetector(
                                                                      onTap:
                                                                          () async {
                                                                        await compOffActionPut(
                                                                            context,
                                                                            'Approved',
                                                                            leave.id);
                                                                        setState(
                                                                            () {
                                                                          _teamCompOffRequest =
                                                                              fetchCompOffRequest(_selectedCompoffText);
                                                                        });
                                                                      },
                                                                      child:
                                                                          Container(
                                                                        decoration:
                                                                            BoxDecoration(
                                                                          borderRadius:
                                                                              BorderRadius.circular(8),
                                                                          color: const Color
                                                                              .fromARGB(
                                                                              126,
                                                                              20,
                                                                              183,
                                                                              25),
                                                                        ),
                                                                        child:
                                                                            Padding(
                                                                          padding: EdgeInsets.symmetric(
                                                                              horizontal: width / 9,
                                                                              vertical: 8),
                                                                          child:
                                                                              Text(
                                                                            'Approve',
                                                                            style:
                                                                                TextStyle(
                                                                              color: AppColor.mainTextColor,
                                                                              fontSize: height * 0.012,
                                                                              fontWeight: FontWeight.w500,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ),

                                                                    GestureDetector(
                                                                      onTap:
                                                                          () async {
                                                                        await compOffActionPut(
                                                                            context,
                                                                            'Rejected',
                                                                            leave.id);
                                                                        setState(
                                                                            () {
                                                                          _teamCompOffRequest =
                                                                              fetchCompOffRequest(_selectedCompoffText);
                                                                        });
                                                                      },
                                                                      child:
                                                                          Container(
                                                                        decoration: BoxDecoration(
                                                                            borderRadius:
                                                                                BorderRadius.circular(8),
                                                                            color: AppColor.mainBGColor),
                                                                        child:
                                                                            Padding(
                                                                          padding: EdgeInsets.symmetric(
                                                                              horizontal: width / 9,
                                                                              vertical: 8),
                                                                          child:
                                                                              Text(
                                                                            'Reject',
                                                                            style:
                                                                                TextStyle(
                                                                              color: AppColor.mainTextColor,
                                                                              fontSize: height * 0.012,
                                                                              fontWeight: FontWeight.w500,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ),
                                                            SizedBox(
                                                                height: height *
                                                                    0.005),
                                                          ],
                                                        ),
                                                      ),
                                                      Container(
                                                        decoration:
                                                            BoxDecoration(
                                                                color: leave.status ==
                                                                        'Pending'
                                                                    ? Colors
                                                                        .amber
                                                                    : leave.status ==
                                                                            'Approved'
                                                                        ? Colors
                                                                            .green
                                                                        : Colors
                                                                            .red,
                                                                borderRadius: BorderRadius.only(
                                                                    topRight: Radius
                                                                        .circular(
                                                                            10),
                                                                    bottomLeft:
                                                                        Radius.circular(
                                                                            20))),
                                                        child: Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  vertical: 0,
                                                                  horizontal:
                                                                      20),
                                                          child: Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(7.0),
                                                            child: Text(
                                                              leave.status,
                                                              style: TextStyle(
                                                                  fontSize:
                                                                      height *
                                                                          0.012,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w400,
                                                                  color: leave.status ==
                                                                          'Pending'
                                                                      ? Colors
                                                                          .black
                                                                      : Colors
                                                                          .white),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                              separatorBuilder:
                                                  (context, index) =>
                                                      SizedBox(height: 10),
                                            );
                                          }
                                        }),
                                  ),
                                ],
                              ),
                            ]),
                      )
                    ],
                  ),
                ),
              ],
            ),
            floatingActionButton: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FloatingActionButton.extended(
                    heroTag: 'btn1',
                    backgroundColor: AppColor.mainThemeColor,
                    onPressed: () {
                      setState(() {
                        switchMode = !switchMode;

                        _myLeaveHistory =
                            fetchLeaveHistory(_selectedText, widget.empID);
                        _myCompOffRequest =
                            fetchOwnCompOffRequest(_selectedCompoffText);
                      });
                    },
                    label: Icon(
                      CupertinoIcons.person_fill,
                      color: Colors.white,
                    )),
                SizedBox(
                  height: height * 0.015,
                ),
                FloatingActionButton.extended(
                  heroTag: 'btn2',
                  backgroundColor: AppColor.mainThemeColor,
                  onPressed: () => showCupertinoModalBottomSheet(
                    expand: true,
                    context: context,
                    barrierColor: const Color.fromARGB(130, 0, 0, 0),
                    backgroundColor: Colors.transparent,
                    builder: (context) => ApplyLeave(),
                  ),
                  label: Text(
                    'Apply Leave',
                    style: TextStyle(color: AppColor.mainFGColor),
                  ),
                ),
              ],
            ));
      }),
    );
  }

  Widget _compoffSelectedButton(String text, double height, double width) {
    Color activeColor;
    Color activeText;

    if (_selectedCompoffText == text) {
      activeColor = AppColor.mainThemeColor;
      activeText = AppColor.mainFGColor;
    } else {
      activeColor = Colors.transparent;
      activeText = const Color.fromARGB(141, 0, 0, 0);
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCompoffText = text;
          _myCompOffRequest = fetchOwnCompOffRequest(_selectedCompoffText);
        });
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          color: activeColor,
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: width * 0.06, vertical: 12),
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

  Widget _selectButton(String text, double height, double width) {
    Color activeColor;
    Color activeText;

    if (_selectedText == text) {
      activeColor = AppColor.mainThemeColor;
      activeText = AppColor.mainFGColor;
    } else {
      activeColor = Colors.transparent;
      activeText = const Color.fromARGB(141, 0, 0, 0);
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedText = text;
          _myLeaveHistory = fetchLeaveHistory(_selectedText, widget.empID);
        });
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          color: activeColor,
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: width * 0.06, vertical: 12),
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
  SizedBox leaveWidget(
      double height, double width, String leave, String leaveCount) {
    return SizedBox(
      width: width * 0.27,
      child: Card(
        color: AppColor.mainBGColor,
        elevation: 4,
        margin: EdgeInsets.all(0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        shadowColor: Colors.black.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 12),
          child: Column(
            children: [
              Text(
                leave,
                style: TextStyle(color: AppColor.mainTextColor2),
              ),
              SizedBox(
                height: 5,
              ),
              Text(
                leaveCount,
                style: TextStyle(
                    color: Color.fromARGB(141, 0, 0, 0),
                    fontSize: height * 0.022),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _compoffFilterBTNTeam(String text, double height, double width) {
    Color activeColor;
    Color activeText;

    if (_selectedCompoffText == text) {
      activeColor = AppColor.mainThemeColor;
      activeText = AppColor.mainFGColor;
    } else {
      activeColor = Colors.transparent;
      activeText = const Color.fromARGB(141, 0, 0, 0);
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCompoffText = text;
            _teamCompOffRequest = fetchCompOffRequest(_selectedCompoffText);
        });
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          color: activeColor,
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: width * 0.06, vertical: 12),
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

  Widget _leaveFilterBTNTeam(String text, double height, double width) {
    Color activeColor;
    Color activeText;

    if (_selectedText == text) {
      activeColor = AppColor.mainThemeColor;
      activeText = AppColor.mainFGColor;
    } else {
      activeColor = Colors.transparent;
      activeText = const Color.fromARGB(141, 0, 0, 0);
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedText = text;
           _teamLeaveRequest = fetchLeaveRequest(_selectedText);
        });
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          color: activeColor,
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: width * 0.06, vertical: 12),
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
