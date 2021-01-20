import 'dart:async';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Mapa extends StatefulWidget {

  String idViagem;

  Mapa({this.idViagem});

  @override
  _MapaState createState() => _MapaState();
}

class _MapaState extends State<Mapa> {

  Completer<GoogleMapController> _controller = Completer();
  Set<Marker> _marcadores = {};
  CameraPosition _cameraInicial = CameraPosition(
    target: LatLng(0,0),
  );
  FirebaseFirestore _db = FirebaseFirestore.instance;

  _adicionarMarcador(LatLng latLng) async {

    List<Placemark> placemarks = await placemarkFromCoordinates(latLng.latitude, latLng.longitude);
    if (placemarks != null && placemarks.isNotEmpty) {
      Placemark endereco = placemarks[0];
      String rua = endereco.thoroughfare;

      Marker marcador = Marker(
          markerId: MarkerId("${latLng.latitude}|${latLng.longitude}"),
          infoWindow: InfoWindow(title: rua),
          position: latLng);

      setState(() {
        _marcadores.add(marcador);
      });

      Map<String, dynamic> viagem = Map();
      viagem["titulo"] = rua;
      viagem["latitude"] = latLng.latitude;
      viagem["longitude"] = latLng.longitude;
      _db.collection("viagens").add(viagem);
    }
  }

  void _adicionarListenerLocalizacao() async {
    Geolocator.getPositionStream(desiredAccuracy: LocationAccuracy.high)
        .listen((Position position) {
      setState(() {
        _cameraInicial = CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 18
        );
        _movimentarCamera();
      });
    });
  }

  _movimentarCamera() async {
    var googleMapController = await _controller.future;
    googleMapController
        .animateCamera(CameraUpdate.newCameraPosition(_cameraInicial));
  }

  _recuperaViagembyId(String id) async {
    if (id != null) {
      var doc = await _db.collection("viagens").doc(id).get();
      var viagem = doc.data();
      String local = viagem["titulo"];
      LatLng latLng = LatLng(viagem["latitude"], viagem["longitude"]);
      Marker marcador = Marker(
          markerId: MarkerId("${latLng.latitude}|${latLng.longitude}"),
          infoWindow: InfoWindow(title: local),
          position: latLng);

      setState(() {
        _marcadores.add(marcador);
        _cameraInicial = CameraPosition(
            target: latLng,
            zoom: 18
        );
        _movimentarCamera();
      });
    } else {
      _adicionarListenerLocalizacao();
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _recuperaViagembyId(widget.idViagem);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Mapa"),
      ),
      body: Container(
        child: GoogleMap(
          markers: _marcadores,
          mapType: MapType.normal,
          initialCameraPosition: _cameraInicial,
          onMapCreated: (GoogleMapController controller) {
            _controller.complete(controller);
          },
          onLongPress: _adicionarMarcador,
        ),
      ),
    );
  }
}
