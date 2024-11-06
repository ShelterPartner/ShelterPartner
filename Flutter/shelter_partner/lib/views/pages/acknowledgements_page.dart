import 'package:flutter/material.dart';

class AcknowledgementsPage extends StatelessWidget {
  const AcknowledgementsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Acknowledgements'),
      ),
      body: const SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              Card.outlined(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'GitHub',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    // Add your GitHub ListTiles here
                    ListTile(title: Text("Jared Jones")),
                    ListTile(title: Text("Renee Jones")),
                    ListTile(
                      title: Text("Kate O'Connor"),
                    ),
                    ListTile(title: Text("Jacob Jones")),
                  ],
                ),
              ),
              SizedBox(height: 25),
              Card.outlined(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'Donations',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    ListTile(title: Text("Ben Jones")),
                    ListTile(title: Text("Renee Jones")),
                    ListTile(title: Text("Lisa Leittermann")),
                  ],
                ),
              ),
              SizedBox(height: 25),
              Card.outlined(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'Other',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    // Add your Other ListTiles here
                    ListTile(
                      title: Text("The Humane Society of Marathon County"),
                      subtitle: Text(
                          "First shelter to use the app. Was willing to try something new. Helped spread the word."),
                    ),
                    ListTile(
                      title: Text("Lisa Leittermann"),
                      subtitle: Text(
                          "Encouraged me to make the app available for other shelters."),
                    ),
                    ListTile(
                      title: Text("Early Adopters"),
                      subtitle: Text(
                          "A lot of shelters were willing to try the app when it was new and unproven and helped guide the direction of the app."),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}