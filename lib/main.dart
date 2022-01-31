// @dart=2.9
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main(){
  runApp(const MaterialApp(
      debugShowCheckedModeBanner: false,
    home: Home(),
  ));
}

class Home extends StatefulWidget {
  const Home({Key key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {

  final _toDoController = TextEditingController();

  List _toDoList = [];

  Map<String, dynamic> _lastRemoved;
  int _lastRemovedPos;

  //A função abaixo declaramos a variavel newToDo como map assim ela poderá receber valores dinamicos (int, string, bool etc)
  //Adicionamos um indice chamado title e ele vai receber o valor do input
  //apos a inserção o campo será limpo e na posição (ok que é um bool receberá false como padrão)
  //logo apos tudo isso ele utilizará a função saveData pra armazenar os dados no banco de dados

  void _addToDo() {
    setState(() {
      Map<String, dynamic> newToDo = Map();
      newToDo['title'] = _toDoController.text;
      _toDoController.text = '';
      newToDo['ok'] = false;
      _toDoList.add(newToDo);
      _saveData();
    });
  }

  //Função Refresh vai ser responsável por ordenar os itens da lista, os itens que não estiverem concluídos sempre serão jogados pra cima

  Future<void> _refresh() async{
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _toDoList.sort((a, b) {
        if(a['ok'] && !b['ok']) {
          return 1;

        } else if(!a['ok'] && b['ok']) {
          return -1;

        } else {
          return 0;
        }
      });

      _saveData();
    });

    return;
  }

  //Aqui o layout e corpo da aplicação como inputs, botoes e etc
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de Tarefas'),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(17, 1, 7, 1),
            child: Row(
              children: [
                Expanded(
                    child: TextField(
                      controller: _toDoController,
                      decoration: const InputDecoration(
                          labelText: 'Nova Tarefa',
                          labelStyle: TextStyle(color: Colors.blueAccent),
                      ),
                    )
                ),
                ElevatedButton(
                  style: ButtonStyle(
                    foregroundColor: MaterialStateProperty.all<Color>(Colors.blueAccent),
                  ),
                  onPressed: () { _addToDo(); },
                  child: const Text('Adicionar', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
          Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 10),
                    itemCount: _toDoList.length,
                    itemBuilder: buildItem,
                  )
              )
          )
        ],
      ),
    );
  }

  //Função responsável pela remoção de algum item da lista assim como também a estilização
  Widget buildItem (BuildContext context, int index){
    return Dismissible(
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      background: Container(
        color: Colors.deepOrange,
        child: const Align(
          alignment: Alignment(0.9, 0.0),
          child: Icon(Icons.delete, color: Colors.white),
        ),
      ),
      direction: DismissDirection.endToStart,
      child: CheckboxListTile(
        title: Text(_toDoList[index]['title']),
        value: _toDoList[index]['ok'],
        secondary: CircleAvatar(
          child: Icon(_toDoList[index]['ok'] ?
          Icons.check : Icons.error
          ),
        ), onChanged: (bool c) {
        setState(() {
          _toDoList[index]['ok'] = c;
          _saveData();
        });
      },
      ),
      onDismissed: (direction) {
        setState(() {
          _lastRemoved = Map.from(_toDoList[index]);
          _lastRemovedPos = index;
          _toDoList.removeAt(index);

          _saveData();

          //Snackbar resposável por exibir o layout apos a deleção do item
          final snack = SnackBar(
            content: Text("Tarefa \"${_lastRemoved["title"]}\", removida! "),
            action: SnackBarAction(label: 'Desfazer', onPressed: () {
              setState(() {
                _toDoList.insert(_lastRemovedPos, _lastRemoved);
                _saveData();
              });
            }),
            duration: const Duration(seconds: 3),
          );

          ScaffoldMessenger.of(context).showSnackBar(snack);
        });
      },
    );

  }

//directory recupera o caminho do arquivo, directory.path recupera o caminho do arquivo concatenado com tarefas.json;
  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File("${directory.path}/tarefas.json");
  }

  //Função necessário por salvar os dados no banco
  Future<File> _saveData() async {
    String data = json.encode(_toDoList);

    final file = await _getFile();

    return file.writeAsString(data);
  }

  //Função responsável por trazer os dados para exibição
  Future<String> _readData() async {

    try {
      final file = await _getFile();

      return file.readAsString();

    } catch (e) {
      return 'Error';

    }
  }

  @override
  void initState() {
    super.initState();

    _readData().then((data) {
      setState(() {
        _toDoList = json.decode(data);
      });
    });
  }
}


