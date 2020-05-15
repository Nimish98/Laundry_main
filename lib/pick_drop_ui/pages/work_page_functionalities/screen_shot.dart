import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:laundry/pick_drop_ui/pages/work_page_functionalities/Json_Road_Snapped.dart';
import 'package:laundry/pick_drop_ui/pages/work_page_functionalities/maps_functions.dart';


class Screen_shot extends StatefulWidget {
	createPolyline object;
	String doc_name;
	Screen_shot(this.object , this.doc_name ,{Key key}): super(key: key);
  @override
  _Screen_shotState createState() => _Screen_shotState();
}




class _Screen_shotState extends State<Screen_shot> {
	
	List<LatLng> _points;
	bool waiting = true;
	Size size;
	Completer<GoogleMapController> _controller = Completer();
	int _polylineIdCounter =1;
	Map<PolylineId,Polyline> polylines = <PolylineId, Polyline>{};
	
	@override
  void initState() {
    super.initState();
    widget.object.stopPolyline();
    print("FetchRoadSnapped function is called ");
    callFetchRoadSnapped();
    print("FetchRoadSnapped function is complited");
    polylineIdGenerate();
    
  }
  
  callFetchRoadSnapped() async{
			_points = await FetchRoadSnapped();
			setState(() {
			  waiting = false;
			});
  }
  
  
  
  
	
	
	LatLngBounds _latLngBounds(List<LatLng> list){
		/*
		    Function to return the boundary based on the points recorded in the list
		that bounds the google_map to a specified boundary and sets the zoom level
		 */
		print("About to check assert function in _latlongBoubds function");
		assert(list.isNotEmpty);
		print(list.length);
		
		print("assert is false exicuting further codes ");
		double x0,x1,y0,y1;
		for(LatLng latLng in list){
			if(x0==null){
				x0 = x1 =latLng.latitude;
				y0 = y1 =latLng.longitude;
			}else{
				if(latLng.latitude > x1) x1 = latLng.latitude;
				if(latLng.latitude < x0) x0 = latLng.latitude;
				if(latLng.longitude > y1) y1 = latLng.longitude;
				if(latLng.longitude < y0) y0 = latLng.longitude;
			}
		}
		print(x0 );
		return LatLngBounds(northeast: LatLng(x1,y1) , southwest: LatLng(x0 , y0));
	}
	
	
	void polylineIdGenerate(){
		print("trip_details invoked ");
		/*
		Makes polyline connecting consecutive recorded points
		 */
		
		final String polylineIdVal = 'polyline_id_$_polylineIdCounter';
		_polylineIdCounter++;
		final PolylineId polylineId = PolylineId(polylineIdVal);
		
		final Polyline polyline =Polyline(
			jointType: JointType.mitered,
			startCap: Cap.roundCap,
			endCap: Cap.squareCap,
			geodesic: false,
			polylineId: polylineId,
			consumeTapEvents: true,
			color: Colors.lightBlueAccent,
			width: 5,
			points: _points,
			onTap: (){},
		);
		setState(() {
			polylines[polylineId]=polyline;
		});
	}
	
	
	uploadPic(png) async {
		final StorageReference firebaseStorageRef =
				FirebaseStorage.instance.ref().child(widget.doc_name);
		firebaseStorageRef.putData(png);
	}
	
	
  @override
  Widget build(BuildContext context) {
		
  	size = MediaQuery.of(context).size;
  	print("Map Container started");
  	
    return waiting ? Container(child: Center(child: CircularProgressIndicator(
    ))):
    Container(
	    height: size.height-200,
	    child: GoogleMap(
		  polylines: Set<Polyline>.of(polylines.values),
		  initialCameraPosition: CameraPosition(target: _points.first),
		  mapType: MapType.normal,
		  zoomGesturesEnabled: true,
		  zoomControlsEnabled: true,
		  onMapCreated: (GoogleMapController controller) async {
			   _controller.complete(controller);
			   controller.animateCamera(CameraUpdate.newLatLngBounds(_latLngBounds(_points),2));
			   await Future.delayed(Duration(seconds: 4));
			   
			   Firestore.instance.collection('Location Points').document(widget.doc_name).setData({
				   '${DateTime.now()}' : 'Screen Short Taken'
			   },merge: true);
			      
			   var png = await controller.takeSnapshot();
			   uploadPic(png);
			   },
	    ),
    );
  }
}
