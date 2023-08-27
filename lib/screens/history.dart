import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gst_calculator/db/db.dart';
import 'package:gst_calculator/model/CalculationHistory.dart';

class CalculationHistoryScreen extends StatelessWidget {
  const CalculationHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: FutureBuilder<List<CalculationHistory>>(
        future: DatabaseHelper.instance.getAllHistories(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}',
                  style: GoogleFonts.roboto());
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Text(
                'No calculation history available.',
                style: GoogleFonts.roboto(),
              );
            }

            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                CalculationHistory history = snapshot.data![index];
                return ListTile(
                  leading: Icon(Icons.bookmark, color: Colors.blue),
                  title: Container(
                    padding: EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius:
                          BorderRadius.circular(16.0), // More rounded borders
                      border: Border.all(color: Colors.grey[400]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(history.expression.toString(),
                            style: GoogleFonts.roboto(fontSize: 16.0)),
                        SizedBox(height: 5.0),
                        Text(history.result.toString(),
                            style: GoogleFonts.roboto(
                                fontSize: 18.0, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      // Implement delete logic here.
                    },
                  ),
                );
              },
            );
          } else {
            return const CircularProgressIndicator();
          }
        },
      ),
    );
  }
}
