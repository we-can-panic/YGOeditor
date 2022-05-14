import sequtils, strformat, dom, tables, math, json, strutils
include karax/prelude
import karax / [kdom, vstyles]
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
  popups: seq[VNode]

proc newCard(name: string, status=Deck, display=Back): Card =
  result = Card(
    id: cards.len+1,
    name: name,
    status: status,
    display: display
  )

proc nameToId(name: string): int =
  result = cards.filterIt(it.name==name)[0].id
proc idToName(id: int): string =
  result = cards.filterIt(it.id==id)[0].name

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

proc makeFirstStatusPop(): VNode =
  cards.load()
  buildHtml tdiv(class="popup"):
    for card in cards:
      tdiv(class="effectEditRow"):
        label:
          text card.name
        text "=>"
        select:
          for p in low(CardPlace)..high(CardPlace):
            if p==card.status:
              option(value=fmt"{p}", selected=""):
                text $p
            else:
              option(value=fmt"{p}"):
                text $p
    tdiv(style="text-align: center; margin-top: 10px;".toCss):
      button:
        text "Commit"
        proc onclick(ev: Event, n: VNode) =
          let
            popupElem = getElementById("lastPopup")
          #[ 以下の構造を想定:
            div:
              label
              text
              select
            ...
            div:
              button
          ]#
          echo %cards
          for i in 0..popupElem.len-2:
            let
              place = popupElem[i][2].value
            cards[i].status = parseEnum[CardPlace]($place)
          cards.save()
          discard popups.pop()

proc makeEffectEditPop(o: Operation): VNode =
  let
    srcId = o.id
    dstIds = o.effect.mapIt(it.id)
  buildHtml tdiv(class="popup"):
    tdiv(class="effectEditRow"):
      select(name="srcSelect"):
        for card in cards:
          if card.id==srcId:
            option(value=fmt"{card.id}", selected=""):
              text card.name
          else:
            option(value=fmt"{card.id}"):
              text card.name
      tdiv: text "の効果"
    for ef in o.effect:
      tdiv(class="effectEditRow"):
        select(name="dstSelect"):
          for card in cards:
            if card.id==ef.id:
              option(value=fmt"{card.id}", selected=""):
                text card.name
            else:
              option(value=fmt"{card.id}"):
                text card.name
        tdiv(style="float: left".toCss): text "を"
        select(name="dstPlacveSelect", style="float: left".toCss):
          for status in [Deck, EXDeck, Hand, Field, Cemetery, Exclusion]:
            if status==ef.cardPlace:
              option(value=fmt"{status}", selected=""):
                text $status
            else:
              option(value=fmt"{status}"):
                text $status
        tdiv: text "に移動"
    tdiv(style="text-align: center; margin-top: 10px;".toCss):
      button:
        text "Commit"
        proc onclick(ev: Event, n: VNode) =
          let
            oidx = operations.find(o)
            popupElem = getElementById("lastPopup")
            srcId = popupElem[0][0].value.parseInt
          #[ 以下の構造を想定:
            div:
              select
              text
            div:
              select
              text
              select
              text
            ...
            div:
              button
          ]#
          var effects: seq[Effect]
          for i in 1..popupElem.len-2:
            let
              dstId = popupElem[i][0].value.parseInt
              dstPlace = $popupElem[i][2].value
            effects.add(newEffect(dstId, parseEnum[CardPlace](dstPlace)))
          operations[oidx] = newOperation(srcId, effects)

          discard popups.pop()

proc makeFirstBox(cards: seq[Card]): VNode =
  buildHtml tdiv(class="box"):
    for card in cards:
      tdiv(class=fmt"line {card.status}")
    proc onclick(ev: Event, n: VNode) =
      popups.add makeFirstStatusPop()

proc makeBox(cards: seq[Card], o: Operation): VNode =
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
      proc onclick(ev: Event, n: VNode) =
        popups.add makeEffectEditPop(o)


proc commit(cards: var seq[Card], o: Operation) =
  for e in o.effect:
    let
      obj = cards.filterIt(it.id==e.id)[0]
      objIdx = cards.find(obj)
    cards[objIdx].status = e.cardPlace
    cards[objIdx].display = e.display

proc download(a: cstring) {.importc.}

proc setData(res: string) =
  let
    content = try:
                res.parseJson
              except JsonParsingError:
                %* {}
  try:
    cards = content["cards"].to(seq[Card])
    operations = content["operations"].to(seq[Operation])
    cards.save()
  except KeyError, JsonKindError:
    discard
proc setData(res: cstring) = setData($res)

func calcAtk(cards: seq[Card], dstPlace: CardPlace = Field): int =
  let
    dstCards = cards.filterIt(it.status==dstPlace)
    atks = {
      "ネクロスライム": 300,
      "スワラルスライム": 200,
      "ラミア": 100,
      "テムジン": 2000,
      "E・テムジン": 2800,
      "アレクサンダー": 2500,
      "C.W.S.D": 3000,
      "": 3000
    }.toTable
  dstCards.mapIt(
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
        cards.makeFirstBox
        for o in operations:
          block: cards.commit(o)
          makeBox(cards, o)
    tdiv(name="display"):
      tdiv(name="json-download"):
        button():
          text "ダウンロード"
          proc onclick(ev: Event, n: VNode) =
            cards.load()
            download (%* {
                        "cards": %cards,
                        "operations": %operations
                      }).pretty.kstring
        input(`type`="file", id="fileupload"):
          proc onchange(ev: Event, n: VNode) =
            let
              elem = cast[InputElement](ev.target)
              file = cast[kdom.File](elem.files[0])
              reader = newFileReader()
            reader.readAsText(file)

            proc resultAsString(f: FileReader, c: proc(res: cstring)) =
              {.emit: """`f`.onload = () => {`c`(`f`.result)}""".}

            reader.resultAsString(setData)

            redraw()

      tdiv(name="display-atk"):
        text fmt"ATK: {cards.calcAtk()}"

    # popup
    for i, popup in popups:
      block:
        if popup.style != nil:
          popup.style.setAttr(zIndex, $(10+i))
        else:
          popup.style = toCss(fmt"zIndex: {10+i};")
        if i==popups.len-1:
          popup.id = "lastPopup"
      popup
    let class = block:
          if popups.len==0: "popup-back hide"
          else: "popup-back"
    tdiv(class=class, style=fmt"width: {window.innerWidth}px; height: {window.innerHeight}px;".toCss):
      proc onclick(ev: Event, n: VNode) =
        discard popups.pop()


when isMainModule and not defined(testing):
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

  setRenderer main