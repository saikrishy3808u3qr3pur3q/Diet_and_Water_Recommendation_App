import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'water_history_view.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/user_details_viewmodel.dart';
import 'package:provider/provider.dart';

class WaterIntakeView extends StatefulWidget {
const WaterIntakeView({super.key});

@override
State<WaterIntakeView> createState() => _WaterIntakeViewState();
}

class _WaterIntakeViewState extends State<WaterIntakeView> with SingleTickerProviderStateMixin {
late TabController _tabController;
double waterConsumed = 0; // ml
double waterGoal = 4000; // ml
double bottleCapacity = 1963; // ml
double _tempWaterConsumed = 0; // Temporary water consumed since last refill
List<Map<String, dynamic>> dailyWaterRecords = [];
List<Map<String, dynamic>> waterRecords = [];
Timer? _timer;
double _data = 0.0; // Current distance data
DateTime _currentDate = DateTime.now(); // Track the current date
bool _hasShownRefillAlert = false; // Track if we've already shown the refill alert
bool _hasInitializedWaterLevel = false; // Track if we've initialized water level

// Stability tracking variables
double _lastStableReading = 0.0;
List<double> _recentReadings = [];
bool _isBottleClosed = true;
int _stableReadingsRequired = 4; // Number of consistent readings to confirm stability
double _stabilityThreshold = 0.5; // Maximum allowed variation for readings to be considered stable

// Bottle dimensions
final double bottleRadius = 5; // cm
final double bottleHeight = 25; // cm

@override
void initState() {
super.initState();
_tabController = TabController(length: 2, vsync: this);
_fetchData();
_timer = Timer.periodic(Duration(seconds: 5), (Timer t) => _fetchData());

// Check for date change every minute
Timer.periodic(Duration(minutes: 1), (Timer t) => _checkForDateChange());
}

@override
void dispose() {
_timer?.cancel();
_tabController.dispose();
super.dispose();
}

void _checkForDateChange() {
final currentDate = DateTime.now();
if (_currentDate.day != currentDate.day ||
_currentDate.month != currentDate.month ||
_currentDate.year != currentDate.year) {
print("Date changed from ${DateFormat('yyyy-MM-dd').format(_currentDate)} to ${DateFormat('yyyy-MM-dd').format(currentDate)}");

// Save the current water reading before resetting
double lastReading = _lastStableReading;

setState(() {
_currentDate = currentDate;
waterConsumed = 0; // Reset water consumed for the new day
dailyWaterRecords = []; // Create a new list instead of clearing

// Don't reset these critical tracking variables
// _hasInitializedWaterLevel = false;

// Add the current water level as an initial reading for the new day
if (_hasInitializedWaterLevel) {
double waterColumnHeight = lastReading;
double waterVolume = pi * bottleRadius * bottleRadius * waterColumnHeight;
double initialAmount = bottleCapacity - waterVolume;

dailyWaterRecords.add({
'time': DateTime.now(),
'amount': initialAmount.floor(),
'note': 'Initial reading for new day',
'isInitial': true
});

waterRecords.add({
'time': DateTime.now(),
'amount': initialAmount.floor(),
'note': 'Initial reading for new day',
'isInitial': true
});
}
});
}
}

Future<void> _fetchData() async {
final url = "https://nutritrack-af35a-default-rtdb.asia-southeast1.firebasedatabase.app/sensor/distance.json";
final response = await http.get(Uri.parse(url));

if (response.statusCode == 200) {
final newData = jsonDecode(response.body);
if (newData is num) {
double currentReading = 25 - newData.toDouble(); // Ensure it's a double
setState(() {
_data = currentReading;

// Initialize water level on first reading if we haven't done so already
if (!_hasInitializedWaterLevel) {
_initializeWaterLevel(currentReading);
} else {
_checkReadingStability(currentReading);
}
});
print("New reading: $currentReading");
} else {
print("Unexpected data format");
}
} else {
print("Failed to fetch data");
}
}

void _initializeWaterLevel(double currentReading) {
// Calculate water volume based on the first reading
double waterColumnHeight = currentReading;
double waterVolume = pi * bottleRadius * bottleRadius * waterColumnHeight;
double initialAmount = bottleCapacity - waterVolume;

setState(() {
_tempWaterConsumed = initialAmount;
// Only mark as initial if reading is -1
bool isInitialReading = currentReading == -1;

// Do NOT add initial amount to total consumption at start of day
// Only track the current level for water remaining calculations

_hasInitializedWaterLevel = true;
_lastStableReading = currentReading; // Set as our first stable reading

// Add initial record but don't count it toward consumption
// Only mark as 'initial' if reading is -1
if (isInitialReading) {
dailyWaterRecords.add({
'time': DateTime.now(),
'amount': initialAmount.floor(),
'note': 'Initial reading',
'isInitial': true
});
waterRecords.add({
'time': DateTime.now(),
'amount': initialAmount.floor(),
'note': 'Initial reading',
'isInitial': true
});
}
});

print("Initial water level set: $currentReading cm, water volume: $waterVolume ml, initial amount in bottle: $initialAmount ml");

// Start collecting readings for stability check
_recentReadings.add(currentReading);
}

void _checkReadingStability(double currentReading) {
// Add the new reading to our recent readings list
_recentReadings.add(currentReading);

// Keep only the most recent readings
if (_recentReadings.length > _stableReadingsRequired) {
_recentReadings.removeAt(0);
}

// Check if we have enough readings to determine stability
if (_recentReadings.length == _stableReadingsRequired) {
// Calculate the maximum difference between readings
double maxDifference = 0;
for (int i = 0; i < _recentReadings.length - 1; i++) {
for (int j = i + 1; j < _recentReadings.length; j++) {
double diff = (_recentReadings[i] - _recentReadings[j]).abs();
if (diff > maxDifference) {
maxDifference = diff;
}
}
}

// Check if readings are stable
bool isCurrentlyStable = maxDifference <= _stabilityThreshold;

// Calculate average of stable readings
double stableReading = _recentReadings.reduce((a, b) => a + b) / _recentReadings.length;

// Update bottle closed status based on stability
if (!isCurrentlyStable && _isBottleClosed) {
// Readings just became unstable - bottle might be open/in use
setState(() {
_isBottleClosed = false;
});
print("Bottle appears to be in use, readings are unstable");
} else if (isCurrentlyStable && !_isBottleClosed) {
// Readings just became stable - bottle is now closed
setState(() {
_isBottleClosed = true;
});
print("Bottle appears to be closed now, readings are stable");

// Compare with last stable reading and update water consumption
_updateWaterIntake(_lastStableReading, stableReading);

// Update the last stable reading
_lastStableReading = stableReading;
}
}
}

void _updateWaterIntake(double previousReading, double currentReading) {
// Calculate water volume change based on stable readings
double previousVolume = pi * bottleRadius * bottleRadius * previousReading; // Volume in cm³
double currentVolume = pi * bottleRadius * bottleRadius * currentReading; // Volume in cm³

// Update the tempWaterConsumed to reflect current water level
setState(() {
_tempWaterConsumed = bottleCapacity - currentVolume;
});

// Only process if there's a meaningful difference (water consumed)
if (previousVolume > currentVolume && (previousVolume - currentVolume) > 1.0) {
// Water level decreased, calculate water consumed
int consumedAmount = (previousVolume - currentVolume).floor();

if (consumedAmount > 0) {
setState(() {
waterConsumed += consumedAmount;

dailyWaterRecords.add({
'time': DateTime.now(),
'amount': consumedAmount,
'isInitial': false // Regular consumption record
});

waterRecords.add({
'time': DateTime.now(),
'amount': consumedAmount,
'isInitial': false // Regular consumption record
});
});

print("Water consumed: $consumedAmount ml");
}
} else if (previousVolume < currentVolume && (currentVolume - previousVolume) > 10.0) {
// Water level increased significantly, bottle was likely refilled
print("Bottle appears to have been refilled");

// Reset the refill alert flag when the bottle is refilled
setState(() {
_hasShownRefillAlert = false;
});

// If refilled, show an alert or handle refill logic
if ((currentVolume - previousVolume) > bottleCapacity * 0.2) {
_showRefillAlert();
}
}
}

void _showRefillAlert() {
showDialog(
context: context,
builder: (BuildContext context) {
return Dialog(
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
backgroundColor: Colors.white,
child: Padding(
padding: const EdgeInsets.all(20.0),
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
const Icon(Icons.local_drink, size: 60, color: Color.fromRGBO(7, 134, 232, 1)),
const SizedBox(height: 10),
const Text(
"Bottle Refilled",
style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
),
const SizedBox(height: 10),
const Text(
"We've detected that you've refilled your bottle. Tracking will continue automatically.",
textAlign: TextAlign.center,
style: TextStyle(fontSize: 16, color: Colors.black87),
),
const SizedBox(height: 20),
ElevatedButton(
onPressed: () {
setState(() {
// Reset temporary water consumed based on current reading
double currentVolume = pi * bottleRadius * bottleRadius * _lastStableReading;
_tempWaterConsumed = bottleCapacity - currentVolume;
});
Navigator.of(context).pop();
},
style: ElevatedButton.styleFrom(
backgroundColor: const Color.fromRGBO(7, 134, 232, 1),
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
),
child: const Text("OK", style: TextStyle(fontSize: 16, color: Colors.white)),
),
],
),
),
);
},
);
}

void _showLowWaterAlert() {
// Only show if we haven't already shown the alert
if (_hasShownRefillAlert) return;

setState(() {
_hasShownRefillAlert = true; // Set the flag to prevent showing again
});

showDialog(
context: context,
builder: (BuildContext context) {
return Dialog(
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
backgroundColor: Colors.white,
child: Padding(
padding: const EdgeInsets.all(20.0),
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
const Icon(Icons.local_drink, size: 60, color: Color.fromRGBO(7, 134, 232, 1)),
const SizedBox(height: 10),
const Text(
"Refill Needed",
style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
),
const SizedBox(height: 10),
const Text(
"Your bottle is almost empty. Please refill to continue tracking water intake.",
textAlign: TextAlign.center,
style: TextStyle(fontSize: 16, color: Colors.black87),
),
const SizedBox(height: 20),
ElevatedButton(
onPressed: () {
Navigator.of(context).pop();
},
style: ElevatedButton.styleFrom(
backgroundColor: const Color.fromRGBO(7, 134, 232, 1),
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
),
child: const Text("OK", style: TextStyle(fontSize: 16, color: Colors.white)),
),
],
),
),
);
},
);
}

// Add this new method to show the edit goal dialog
void _showEditGoalDialog() {
TextEditingController _goalController = TextEditingController(text: waterGoal.toInt().toString());

showDialog(
context: context,
builder: (BuildContext context) {
return Dialog(
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
backgroundColor: Colors.white,
child: Padding(
padding: const EdgeInsets.all(20.0),
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
const Icon(Icons.edit, size: 40, color: Color.fromRGBO(7, 134, 232, 1)),
const SizedBox(height: 10),
const Text(
"Edit Water Goal",
style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
),
const SizedBox(height: 20),
TextFormField(
controller: _goalController,
keyboardType: TextInputType.number,
decoration: InputDecoration(
labelText: "Daily Water Goal (ml)",
border: OutlineInputBorder(
borderRadius: BorderRadius.circular(10.0),
),
prefixIcon: const Icon(Icons.water_drop, color: Color.fromRGBO(7, 134, 232, 1)),
filled: true,
fillColor: Colors.grey.shade100,
),
),
const SizedBox(height: 30),
Row(
mainAxisAlignment: MainAxisAlignment.spaceEvenly,
children: [
ElevatedButton(
onPressed: () {
Navigator.of(context).pop();
},
style: ElevatedButton.styleFrom(
backgroundColor: Colors.grey.shade300,
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
),
child: const Text("Cancel", style: TextStyle(fontSize: 16, color: Colors.black87)),
),
ElevatedButton(
onPressed: () {
// Update the water goal
try {
int newGoal = int.parse(_goalController.text);
if (newGoal > 0) {
setState(() {
waterGoal = newGoal.toDouble();
});
Navigator.of(context).pop();

// Show confirmation snackbar
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Text('Water goal updated to $newGoal ml'),
backgroundColor: Colors.green,
behavior: SnackBarBehavior.floating,
duration: const Duration(seconds: 2),
),
);
} else {
// Show error for negative or zero value
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text('Please enter a positive number'),
backgroundColor: Colors.red,
behavior: SnackBarBehavior.floating,
),
);
}
} catch (e) {
// Show error for invalid input
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text('Please enter a valid number'),
backgroundColor: Colors.red,
behavior: SnackBarBehavior.floating,
),
);
}
},
style: ElevatedButton.styleFrom(
backgroundColor: const Color.fromRGBO(7, 134, 232, 1),
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
),
child: const Text("Save", style: TextStyle(fontSize: 16, color: Colors.white)),
),
],
),
],
),
),
);
},
);
}

// Add this new method to reset the current water left
void _resetWaterLeft() {
setState(() {
double currentVolume = pi * bottleRadius * bottleRadius * _lastStableReading;
_tempWaterConsumed = bottleCapacity - currentVolume;
});

// Show confirmation snackbar
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text('Water left has been reset'),
backgroundColor: Colors.green,
behavior: SnackBarBehavior.floating,
duration: Duration(seconds: 2),
),
);
}

@override
Widget build(BuildContext context) {
final userDetailsViewModel = Provider.of<UserDetailsViewModel>(context);
final prediction = userDetailsViewModel.predictionResponse;

// Update waterGoal if prediction is available
if (prediction != null && prediction.containsKey("recommended_water_liters")) {
double recommendedWaterLiters = prediction["recommended_water_liters"];
setState(() {
waterGoal = recommendedWaterLiters * 1000; // Convert liters to milliliters
});
}

return Scaffold(
backgroundColor: const Color(0xFF0D46CB), // Dark blue background
appBar: AppBar(
backgroundColor: const Color(0xFF1F5ACE), // Lighter dark blue
title: const Text("Water Intake", style: TextStyle(color: Colors.white)),
automaticallyImplyLeading: false,
actions: [
// Add a settings icon to edit the water goal
IconButton(
icon: const Icon(Icons.settings, color: Colors.white),
onPressed: _showEditGoalDialog,
tooltip: "Edit Water Goal",
),
],
),
body: Column(
children: [
TabBar(
controller: _tabController,
indicatorColor: Colors.cyanAccent,
labelColor: Colors.white,
unselectedLabelColor: Colors.white.withOpacity(0.6),
tabs: const [
Tab(text: "Today"),
Tab(text: "History"),
],
),
Expanded(
child: TabBarView(
controller: _tabController,
children: [
SingleChildScrollView(
child: WaterIntakeContent(
waterConsumed: waterConsumed,
waterGoal: waterGoal,
bottleCapacity: bottleCapacity,
tempWaterConsumed: _tempWaterConsumed,
waterRecords: dailyWaterRecords,
data: _data, // Pass the data to the content widget
isBottleClosed: _isBottleClosed, // Pass bottle status
onLowWaterAlert: _showLowWaterAlert,
onEditGoal: _showEditGoalDialog, // Pass the edit goal callback
onResetWaterLeft: _resetWaterLeft, // Pass the reset water left callback
),
),
WaterHistoryView(
waterRecords: waterRecords,
),
],
),
),
],
),
);
}
}

class WaterIntakeContent extends StatelessWidget {
final double waterConsumed;
final double waterGoal;
final double bottleCapacity;
final double tempWaterConsumed;
final List<Map<String, dynamic>> waterRecords;
final double data;
final bool isBottleClosed;
final VoidCallback onLowWaterAlert;
final VoidCallback onEditGoal; // Add this callback
final VoidCallback onResetWaterLeft; // Add this callback

const WaterIntakeContent({
super.key,
required this.waterConsumed,
required this.waterGoal,
required this.bottleCapacity,
required this.tempWaterConsumed,
required this.waterRecords,
required this.data,
required this.isBottleClosed,
required this.onLowWaterAlert,
required this.onEditGoal, // Make it required
required this.onResetWaterLeft, // Make it required
});

@override
Widget build(BuildContext context) {
final screenWidth = MediaQuery.of(context).size.width;
// Check if water is low and show alert if needed
WidgetsBinding.instance.addPostFrameCallback((_) {
if ((bottleCapacity - tempWaterConsumed) < 100) {
onLowWaterAlert();
}
});

return Stack(
children: [
Column(
children: [
SizedBox(height: screenWidth * 0.05),
Stack(
alignment: Alignment.center,
children: [
// Outer Circular Indicator (Bottle Remaining)
Container(
decoration: BoxDecoration(
shape: BoxShape.circle,
boxShadow: [
BoxShadow(
color: Colors.blue.withOpacity(0.4),
blurRadius: 20,
spreadRadius: 5,
),
],
),
child: CircularPercentIndicator(
radius: 140.0,
lineWidth: 10.0,
animation: true,
percent: ((bottleCapacity - tempWaterConsumed) / bottleCapacity).clamp(0.0, 1.0),
circularStrokeCap: CircularStrokeCap.round,
linearGradient: LinearGradient(
colors: [Colors.blueAccent.shade400, Colors.blue.shade700],
),
backgroundColor: Colors.transparent,
center: Container(), // Avoids cluttering the center
),
),

// Inner Circular Indicator (Water Intake)
Container(
decoration: BoxDecoration(
shape: BoxShape.circle,
boxShadow: [
BoxShadow(
color: Colors.greenAccent.withOpacity(0.4),
blurRadius: 20,
spreadRadius: 5,
),
],
),
child: CircularPercentIndicator(
radius: 120.0,
lineWidth: 20.0,
animation: true,
percent: (waterConsumed / waterGoal).clamp(0.0, 1.0),
circularStrokeCap: CircularStrokeCap.round,
linearGradient: LinearGradient(
colors: [Colors.green.shade400, Colors.greenAccent.shade700],
),
backgroundColor: Colors.grey.shade300,
center: Column(
mainAxisAlignment: MainAxisAlignment.center,
children: [
Text(
"Water Intake",
style: TextStyle(
fontSize: 20,
fontWeight: FontWeight.w600,
color: Colors.blueGrey.shade800,
),
),
Text(
"${waterConsumed.toInt()} ml",
style: TextStyle(
fontSize: 28,
fontWeight: FontWeight.bold,
color: Colors.blue.shade800,
),
),
Row(
mainAxisSize: MainAxisSize.min,
children: [
Text(
"Goal: ${waterGoal.toInt()} ml",
style: TextStyle(
fontSize: 20,
color: Colors.green.shade700,
),
),
const SizedBox(width: 5),
// Add a small edit icon next to the goal
InkWell(
onTap: onEditGoal,
child: Icon(
Icons.edit,
size: 16,
color: Colors.blue.shade700,
),
),
],
),
],
),
),
),
],
),
const SizedBox(height: 20),
_buildRemainingDisplay(),
const SizedBox(height: 20),

// Bottle status indicator
Padding(
padding: const EdgeInsets.symmetric(horizontal: 20),
child: Card(
elevation: 5,
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
child: Container(
padding: const EdgeInsets.all(15),
decoration: BoxDecoration(
gradient: LinearGradient(
colors: isBottleClosed
? [Colors.green.shade300, Colors.green.shade600]
    : [Colors.orange.shade300, Colors.orange.shade600],
),
borderRadius: BorderRadius.circular(15),
),
child: Row(
mainAxisAlignment: MainAxisAlignment.center,
children: [
Icon(
isBottleClosed ? Icons.check_circle : Icons.access_time,
color: Colors.white,
size: 24,
),
const SizedBox(width: 10),
Text(
isBottleClosed
? "Bottle Closed - Tracking Active"
    : "Bottle In Use - Waiting for Stability",
style: const TextStyle(
fontSize: 16,
fontWeight: FontWeight.bold,
color: Colors.white,
),
),
],
),
),
),
),
const SizedBox(height: 15),

// Warning Card when water remaining is below 100ml
if ((bottleCapacity - tempWaterConsumed) < 100)
Padding(
padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
child: Card(
elevation: 10,
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
child: Container(
decoration: BoxDecoration(
borderRadius: BorderRadius.circular(20),
gradient: LinearGradient(
colors: [Colors.redAccent.shade200, Colors.redAccent.shade700],
begin: Alignment.topLeft,
end: Alignment.bottomRight,
),
),
padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
child: const Column(
crossAxisAlignment: CrossAxisAlignment.center,
children: [
Icon(
Icons.warning_amber_rounded,
color: Colors.white,
size: 40,
),
SizedBox(height: 10),
Text(
"Low Water Alert!",
style: TextStyle(
fontSize: 20,
fontWeight: FontWeight.bold,
color: Colors.white,
),
),
SizedBox(height: 8),
Text(
"Your bottle is almost empty. Please refill soon.",
textAlign: TextAlign.center,
style: TextStyle(
fontSize: 16,
color: Colors.white70,
),
),
],
),
),
),
),

const SizedBox(height: 20),
_buildTodaysRecord(),
],
),
Positioned(
top: 10,
right: 10,
child: ElevatedButton(
onPressed: onResetWaterLeft,
style: ElevatedButton.styleFrom(
backgroundColor: Colors.blue.shade600,
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
padding: const EdgeInsets.all(10), // Make it a square
),
child: const Icon(Icons.refresh, color: Colors.white),
),
),
],
);
}

Widget _buildWaterInfoCard(String title, String value, Color color, IconData icon) {
return Container(
padding: const EdgeInsets.all(15),
decoration: BoxDecoration(
color: color.withOpacity(0.3), // Adjust alpha for a subtle background
borderRadius: BorderRadius.circular(15),
),
child: Row(
mainAxisSize: MainAxisSize.min,
children: [
Icon(icon, color: color, size: 30),
const SizedBox(width: 10),
Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
title,
style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87),
),
Text(
value,
style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
),
],
),
],
),
);
}

Widget _buildRemainingDisplay() {
return Padding(
padding: const EdgeInsets.symmetric(horizontal: 20),
child: Wrap( // Wrap instead of Row to avoid overflow
spacing: 10, // Adds space between cards
runSpacing: 10, // Moves cards to a new line if needed
alignment: WrapAlignment.center, // Centers items if they wrap
children: [
_buildWaterInfoCard(
"To Target",
"${(waterGoal - waterConsumed).toInt().clamp(0, waterGoal.toInt())} ml",
Colors.redAccent,
Icons.flag,
),
_buildWaterInfoCard(
"Water Left",
"${(bottleCapacity - tempWaterConsumed).toInt().clamp(0, bottleCapacity.toInt())} ml",
Colors.green,
Icons.local_drink,
),
],
),
);
}

Widget _buildTodaysRecord() {
// Filter out the initial reading from the displayed records
final filteredRecords = waterRecords.where((record) => record['isInitial'] != true).toList();

return ListView.builder(
shrinkWrap: true,
physics: const NeverScrollableScrollPhysics(),
itemCount: filteredRecords.length,
itemBuilder: (context, index) {
final record = filteredRecords.reversed.toList()[index]; // Reverse the list
final time = DateFormat('yyyy-MM-dd – HH:mm').format(record['time']);
final amount = record['amount'];
final note = record['note'] ?? '';

return Card(
margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 20),
elevation: 5,
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
child: ListTile(
leading: const Icon(Icons.water_drop, color: Colors.blueAccent),
title: Text("$amount ml"),
subtitle: Text("at $time ${note.isNotEmpty ? '• $note' : ''}"),
trailing: const Icon(Icons.check_circle, color: Colors.green),
),
);
},
);
}
}
