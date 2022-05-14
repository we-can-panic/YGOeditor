discard """
  targets: "js"
  output: '''
'''
"""

include ../index

import unittest

block class:
  block card:
    var card1 = newCard("A", Hand, Front)
    check card1.name=="A"
    check card1.status==Hand
    check card1.display==Front
    check card1.id==1
    cards.add card1
    var card2 = newCard("B")
    check card2.name=="B"
    check card2.id==2
    cards.add card2
  block operation:
    var
      ef = newEffect("A", Hand, Back)
      op = newOperation("A", ef)
    check op.id==1
    check op.effect[0].id==1
    check op.effect[0].cardPlace==Hand
    check op.effect[0].display==Back
    var
      ef1 = newEffect("A", Field)
      ef2 = newEffect("A", Field)
    check ef1.id==ef2.id
    check ef1.cardPlace==ef2.cardPlace
    check ef1.display==ef2.display
    expect IndexDefect:
      var ef3 = newEffect("C", EXDeck)
    expect IndexDefect:
      var
        ef3 = newEffect("B", EXDeck)
        op3 = newOperation("C", ef3)

block utils:
  var op = newOperation("A", newEffect("A", Field, Back))
  let id = cards.mapIt(it.name).find("A")
  check cards[id].name=="A"
  check cards[id].status==Hand
  check cards[id].display==Front
  cards.commit(op)
  check cards[id].name=="A"
  check cards[id].status==Field
  check cards[id].display==Back
  block atk:
    var sample = @[
          newCard("スワラルスライム", Field),
          newCard("ラミア", Field),
          newCard("テムジン", Field),
          newCard("C.W.S.D", Field)
        ]
    check calcAtk(sample)==5300
    sample[1] = newCard("ラミア", Cemetery)
    check calcAtk(sample)==5200

block file:
  let
    sample = (%*
      {
        "cards": [
          {
            "id": 1,
            "name": "スワラルスライム",
            "status": "Exclusion",
            "display": "Front"
          }
        ],
        "operations": [
          {
            "id": 1,
            "effect": [
              {
                "id": 1,
                "cardPlace": "Cemetery",
                "display": "Front"
              }
            ]
          }
        ]
      }
    ).pretty
  sample.setData()
  check cards.len==1
  check cards[0].name=="スワラルスライム"
  check operations.len==1
  check operations[0].id==1


