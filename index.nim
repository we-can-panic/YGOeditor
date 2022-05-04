import sequtils, strformat, dom, tables, math, json
include karax/prelude
import paintutil

type
  Card = ref object
    id: int
    name: string
    status: CardPlace
    display: Display
  CardPlace = enum
    Deck, EXDeck, Hand, Field, Cemetery, Exclusion
  Display = enum
    Front, Back

  Operation = ref object
    id: int
    effect: seq[Effect]
  Effect = ref object
    id: int
    cardPlace: CardPlace
    display: Display

var
  cards: seq[Card]
  iniCardsData: string
  operations: seq[Operation]

proc newCard(name: string, status=Deck, display=Back): Card =
  result = Card(
    id: cards.len+1,
    name: name,
    status: status,
    display: display
  )

proc nameToId(name: string): int =
  result = cards.filterIt(it.name==name)[0].id

func newEffect(id: int, cardPlace: CardPlace, display: Display = Front): Effect =
  result = Effect(id: id, cardPlace: cardPlace, display: display)
proc newEffect(name: string, cardPlace: CardPlace, display: Display = Front): Effect =
  result = Effect(id: nameToId(name), cardPlace: cardPlace, display: display)

func newOperation(id: int, effect: seq[Effect]): Operation =
  result = Operation(id: id, effect: effect)
proc newOperation(name: string, effect: varargs[Effect]): Operation =
  result = Operation(id: nameToId(name), effect: @effect)

func toJson(card: Card): JsonNode =
  result = %[
    ("id", %card.id),
    ("name", %card.name),
    ("status", %card.status),
    ("display", %card.display)
  ]
func `%`(card: Card): JsonNode = toJson(card)

func toJson(e: Effect): JsonNode =
  result = %[
    ("id", %e.id),
    ("cardPlace", %e.cardPlace),
    ("display", %e.display)
  ]
func `%`(e: Effect): JsonNode = toJson(e)

func toJson(o: Operation): JsonNode =
  result = %[
    ("id", %o.id),
    ("effect", %(o.effect.mapIt(%it)))
  ]
func `%`(o: Operation): JsonNode = toJson(o)

proc save(cards: seq[Card]) =
  iniCardsData = (%cards).pretty
proc load(cards: var seq[Card]) =
  cards = iniCardsData.parseJson.to(seq[Card])

func makeBox(cards: seq[Card], o: Operation): VNode =
  let
    srcId = o.id
    dstIds = o.effect.mapIt(it.id)
  buildHtml tdiv(class="box"):
      for card in cards:
        tdiv(class=fmt"line {card.status}"):
          if card.id == srcId:
            drawStar()
          elif card.id in dstIds:
            drawPoint()
          else:
            drawNone()

func makeBox(cards: seq[Card]): VNode =
  makeBox(cards, newOperation(0, @[newEffect(0, Hand)]))

proc commit(cards: var seq[Card], o: Operation): VNode =
  for e in o.effect:
    let
      obj = cards.filterIt(it.id==e.id)[0]
      objIdx = cards.find(obj)
    cards[objIdx].status = e.cardPlace
    cards[objIdx].display = e.display
  makeBox(cards, o)

###
block ini:
  cards.add newCard("スワラルスライム", Hand)
  cards.add newCard("ネクロスライム", Hand)
  cards.add newCard("ラミア", Hand)
  cards.add newCard("テムジン", EXDeck)
  cards.add newCard("アレクサンダー", EXDeck)
  cards.add newCard("C.W.S.D", EXDeck)
  cards.add newCard("E・テムジン", EXDeck)
  cards.add newCard("何某", EXDeck)
  operations.add newOperation("スワラルスライム", newEffect("スワラルスライム", Cemetery), newEffect("ネクロスライム", Cemetery), newEffect("テムジン", Field))
  operations.add newOperation("スワラルスライム", newEffect("ラミア", Field), newEffect("スワラルスライム", Exclusion))
  operations.add newOperation("テムジン", newEffect("ネクロスライム", Field))
  operations.add newOperation("アレクサンダー", newEffect("アレクサンダー", Field), newEffect("テムジン", Cemetery), newEffect("ラミア", Cemetery))
  operations.add newOperation("ラミア", newEffect("ラミア", Field), newEffect("ネクロスライム", Cemetery))
  operations.add newOperation("アレクサンダー", newEffect("テムジン", Field))
  operations.add newOperation("C.W.S.D", newEffect("C.W.S.D", Field), newEffect("アレクサンダー", Cemetery), newEffect("ラミア", Cemetery))
  operations.add newOperation("ネクロスライム", newEffect("ネクロスライム", Exclusion), newEffect("アレクサンダー", Exclusion), newEffect("E・テムジン", Field))
  operations.add newOperation("何某", newEffect("何某", Field))
  operations.add newOperation("E・テムジン", newEffect("ラミア", Field))

  cards.save()
  echo (%* cards).pretty
  echo (%* operations).pretty

###

proc download(a: cstring) {.importc.}

func calcAtk(cards: seq[Card]): int =
  let atks = {
    "ネクロスライム": 300,
    "スワラルスライム": 200,
    "ラミア": 100,
    "テムジン": 2000,
    "E・テムジン": 2800,
    "アレクサンダー": 2500,
    "C.W.S.D": 3000,
    "": 3000
  }.toTable
  cards.mapIt(
      if atks.hasKey(it.name):
        atks[it.name]
      else:
        0
      ).sum


proc main(): VNode =
  cards.load()
  buildHtml tdiv:
    tdiv(name="parette"):
      tdiv(id="cardlist"):
        for c in cards:
          tdiv(class="cardname"):
            text c.name
      tdiv(id="lines"):
        cards.makeBox
        for o in operations:
          cards.commit(o)
    tdiv(name="display"):
      tdiv(name="json-download"):
        button():
          text "ダウンロード"
          proc onclick(ev: Event, n: VNode) =
            download (%* {
                        "cards": %cards,
                        "operations": %operations
                      }).pretty.kstring
      tdiv(name="display-atk"):
        text fmt"ATK: {cards.filterIt(it.status==Field).calcAtk()}"

setRenderer main