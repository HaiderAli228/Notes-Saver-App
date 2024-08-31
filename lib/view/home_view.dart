import 'package:flutter/material.dart';
import 'package:notes/data/local/database.dart';
import 'package:notes/routes/routes_name.dart';
import 'package:notes/utils/app_colors.dart';
import 'package:notes/utils/toast_msg.dart';
import 'package:flutter/rendering.dart';

import 'add_new_notes_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with TickerProviderStateMixin {
  List<Map<String, dynamic>> notesList = [];
  List<Map<String, dynamic>> filteredNotesList = [];
  DatabaseHelper? databaseHelperObject;
  TextEditingController searchController = TextEditingController();
  List<bool> expandedStates = [];
  List<bool> showReadMoreButtons = [];

  @override
  void initState() {
    super.initState();
    databaseHelperObject = DatabaseHelper.getInstance;
    accessNotes();
  }

  void accessNotes() async {
    notesList = await databaseHelperObject!.fetchAllNotes();
    setState(() {
      filteredNotesList = notesList;
      expandedStates = List<bool>.filled(notesList.length, false);
      showReadMoreButtons = List<bool>.filled(notesList.length, false);
      _checkReadMoreVisibility();
    });
  }

  void filterNotes(String query) {
    final filtered = notesList.where((note) {
      final title = note[databaseHelperObject!.tableSecondColumnIsTitle]
          .toString()
          .toLowerCase();
      return title.contains(query.toLowerCase());
    }).toList();

    setState(() {
      filteredNotesList = filtered;
    });
  }

  void _checkReadMoreVisibility() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (int i = 0; i < filteredNotesList.length; i++) {
        final text = filteredNotesList[i][databaseHelperObject!.tableThirdColumnIsDescription];
        final textSpan = TextSpan(
          text: text,
          style: const TextStyle(fontFamily: "Poppins"),
        );
        final textPainter = TextPainter(
          text: textSpan,
          maxLines: 3,
          textDirection: TextDirection.ltr,
        );
        textPainter.layout(maxWidth: MediaQuery.of(context).size.width - 150); // Subtracting the padding, icon, etc.
        final didExceedMaxLines = textPainter.didExceedMaxLines;

        if (didExceedMaxLines) {
          showReadMoreButtons[i] = true;
        } else {
          showReadMoreButtons[i] = false;
        }
      }
      setState(() {});
    });
  }

  void _handleMenuSelection(String value, int noteId) {
    if (value == 'Update') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddNewNotesView(
            note: filteredNotesList.firstWhere((note) =>
            note[databaseHelperObject!.tableFirstColumnIsSeNum] == noteId),
          ),
        ),
      ).then((_) => accessNotes());
    } else if (value == 'Delete') {
      databaseHelperObject!.deleteNotes(indexIs: noteId).then((success) {
        if (success) {
          accessNotes();
          setState(() {
            ToastMsg.toastMsg("Deleted");
          });
        } else {
          ToastMsg.toastMsg("Not Deleted");
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.themeColor,
        centerTitle: true,
        title: const Text(
          "Notes",
          style: TextStyle(
            color: AppColors.themeTextColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: "Poppins",
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: TextFormField(
              controller: searchController,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.all(15),
                hintText: "Search by Title",
                hintStyle: const TextStyle(fontFamily: "Poppins"),
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: InputBorder.none,
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade100),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade100),
                ),
              ),
              onChanged: filterNotes,
            ),
          ),
          Expanded(
            child: filteredNotesList.isNotEmpty
                ? ListView.builder(
              itemCount: filteredNotesList.length,
              itemBuilder: (context, index) {
                final note = filteredNotesList[index];
                final noteId = note[databaseHelperObject!.tableFirstColumnIsSeNum];
                final isExpanded = expandedStates[index];

                return AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: Container(
                    padding: const EdgeInsets.only(
                        top: 5, left: 5, bottom: 5),
                    margin: const EdgeInsets.symmetric(
                        horizontal: 15, vertical: 6),
                    decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10)),
                    child: ListTile(
                      title: Text(
                        note[databaseHelperObject!.tableSecondColumnIsTitle],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontFamily: "Poppins",
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            note[databaseHelperObject!.tableThirdColumnIsDescription],
                            maxLines: isExpanded ? null : 3,
                            style: const TextStyle(
                              fontFamily: "Poppins",
                            ),
                          ),
                          if (showReadMoreButtons[index])
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  expandedStates[index] = !isExpanded;
                                });
                              },
                              child: Text(
                                isExpanded ? "Hide" : "Read More",
                                style: const TextStyle(
                                  color: AppColors.themeColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      trailing: PopupMenuButton<String>(
                        color: Colors.grey.shade100,
                        onSelected: (value) =>
                            _handleMenuSelection(value, noteId),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'Update',
                            child: Text('Update'),
                          ),
                          const PopupMenuItem(
                            value: 'Delete',
                            child: Text('Delete'),
                          ),
                        ],
                        icon: const Icon(Icons.more_vert_rounded),
                      ),
                    ),
                  ),
                );
              },
            )
                : const SingleChildScrollView(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 60,
                    ),
                    Image(
                      image: AssetImage("assets/images/1.png"),
                      fit: BoxFit.cover,
                      width: 300,
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    Text(
                      "No Notes Created Yet",
                      style: TextStyle(
                        fontFamily: "Poppins",
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        backgroundColor: AppColors.themeColor,
        child: const Icon(
          Icons.add,
          size: 30,
          color: AppColors.themeTextColor,
        ),
        onPressed: () async {
          final isNewNoteAdded = await Navigator.pushNamed<bool?>(
            context,
            RoutesName.addNewScreen,
          );
          if (isNewNoteAdded == true) {
            accessNotes();
          }
        },
      ),
    );
  }
}
