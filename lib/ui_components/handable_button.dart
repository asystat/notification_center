import 'package:flutter/material.dart';

typedef void OnButtonPressed();

class HandableButton extends StatefulWidget {
  final String title;
  final OnButtonPressed onPressed;
  final bool enabled;

  HandableButton(this.title, this.onPressed, this.enabled);

  State<StatefulWidget> createState() => new HandableButtonState();
}

class HandableButtonState extends State<HandableButton> {
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return new Table(
      children: [
        new TableRow(children: [
          new FlatButton(
            disabledColor: Color.fromARGB(180, 212, 86, 83),
            disabledTextColor: Colors.white,
            color: Color.fromARGB(255, 212, 86, 83),
            textColor: Colors.white,
            padding: EdgeInsets.all(8.0),
            child: new Text(widget.title),
            onPressed: widget.enabled ? widget.onPressed : null,
          )
        ]),
        new TableRow(children: [
          Container(
            height: 8.0,
          )
        ]),
      ],
    );
  }
}