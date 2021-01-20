import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'mapa.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {

  final _controller = StreamController<QuerySnapshot>.broadcast();
  FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _adicionarListenerViagens();
  }

  _adicionarListenerViagens() {
    final stream = _db.collection("viagens").snapshots();

    stream.listen((dados) {
      _controller.add(dados);
    });
  }

  @override
  Widget build(BuildContext context) {

    void _abrirMapa(String id) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => Mapa(idViagem: id)));
    }

    void _excluirViagem(String id) {
      _db.collection("viagens").doc(id).delete();
    }

    void _adicionarLocal() {
      Navigator.push(context, MaterialPageRoute(builder: (_) => Mapa()));
    }

    return Scaffold(
      appBar: AppBar(title: Text("Minhas Viagens")),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        backgroundColor: Color(0xFF0066cc),
        onPressed: () {
          _adicionarLocal();
        },
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _controller.stream,
        builder: (context, snapshot) {
          if (snapshot == null) {
            return Container(child: Text("Fudeu"));
          }
          if (!snapshot.hasData) {
            return Center(
              child: Column(
                children: [
                  Text("Carregando viagens..."),
                  CircularProgressIndicator()
                ],
              ),
            );
          }
          if (snapshot.hasError) {
            return Expanded(child: Text("Erro ao carregar dados"));
          }
          if (snapshot.hasData) {
            List<DocumentSnapshot> viagens = snapshot.data.docs.toList();

            return Column(
              children: [
                Expanded(
                    child: ListView.builder(
                      itemCount: viagens.length,
                      itemBuilder: (context, index) {
                        DocumentSnapshot viagem = viagens[index];
                        String local = viagem["titulo"];
                        String uid = viagem.id;
                        return GestureDetector(
                          child: Card(
                            child: ListTile(
                              title: Text(local),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  GestureDetector(
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Icon(Icons.remove_circle,
                                          color: Colors.red),
                                    ),
                                    onTap: () {
                                      _excluirViagem(uid);
                                    },
                                  )
                                ],
                              ),
                            ),
                          ),
                          onTap: () {
                            _abrirMapa(uid);
                          },
                        );
                      },
                    )
                )
              ],
            );
          }
        }
      ),
    );
  }
}
