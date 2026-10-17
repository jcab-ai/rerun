import Foundation

/// Hand-written stories for the sample world, so every sticker is playable
/// before any model is set up. Each person texts the way their voice profile says.
public enum DemoStories {
    public static let all: [ScriptedStory] = [
        lisbon, bigSur, weddingFight, fantasyLeague, theo30th, voiceMemos,
        corolla, dadCooks, moveOut, sushi, theoCouch, firstUUp, berlin,
    ]

    private static func l(_ text: String, _ from: String? = nil) -> ScriptedLine {
        ScriptedLine(text, from: from)
    }

    // MARK: Maya

    static let lisbon = ScriptedStory(momentID: "lisbon", speakerID: "maya", chapters: [
        ScriptedChapter(
            title: "alfama, one more song", clock: "1:52",
            narration: "A fado bar in Alfama, a candle stuck in a wine bottle. Your flight is at 7:10. Maya is in the bathroom line, texting you from eleven feet away.",
            aside: "she's already decided. she's just letting you think it's a vote.",
            messages: [l("ok hear me out"), l("ONE more song"), l("the singer looked at me jules. LOOKED. i have to stay")],
            choices: [
                ScriptedChoice("“one more. then bed. i mean it”", replies: [l("deal"), l("(it will not be one)")]),
                ScriptedChoice("“our flight is in five hours maya”", replies: [l("FIVE whole hours"), l("thats like 40 songs"), l("i did the math")]),
                ScriptedChoice("order two more ginjinhas", sends: "🍒🍒 on the table", replies: [l("oh so ur the problem"), l("i love the problem")]),
            ]
        ),
        ScriptedChapter(
            title: "gate 14", clock: "6:52",
            narration: "6:52 am, Humberto Delgado Airport. Maya is on the floor by the window. You're two minutes out, running, holding her bag.",
            aside: "she's typing like she's about to cry or laugh. hard to tell.",
            messages: [
                l("jules"), l("JULES"), l("the gate is CLOSED"),
                l("it says departed. in red. the red word"), l("i'm sitting on the floor"),
                l("you have my bag and not a time machine"),
            ],
            choices: [
                ScriptedChoice("“we're getting the 9:15. i'm buying the pastéis”", replies: [l("ok wait"), l("that's actually so hot of you"), l("custard me")]),
                ScriptedChoice("“this is your fault and you know it”", replies: [l("WOW"), l("who said “one more song”"), l("it was u. u said it")]),
                ScriptedChoice("say nothing. send her the sunrise.", sends: "📷 gate 14 at sunrise", replies: [l("why is it so pretty here"), l("i hate that im not mad anymore")]),
            ]
        ),
        ScriptedChapter(
            title: "the 9:15 standby list", clock: "7:40",
            narration: "The agent says two seats on the 9:15 — maybe. There are eleven names on the standby list. Yours are ten and eleven. Maya is negotiating with a vending machine.",
            aside: "the vending machine is winning.",
            messages: [l("update the machine took my last 2 euros"), l("it gave me nothing"), l("not even a bolacha"), l("is this a sign. like a sign sign")],
            choices: [
                ScriptedChoice("“i'm going to charm the gate agent”", replies: [l("u?? charm??"), l("ok go"), l("i'll be over here praying to the coffee")]),
                ScriptedChoice("“what if we just… stayed another day”", replies: [l("dont tempt me"), l("my boss thinks im at a conference"), l("about what. about WHAT jules")]),
                ScriptedChoice("split the last pastel de nata", sends: "🥧 half for you", replies: [l("ur the best person i know"), l("this is my best friend's wedding but its a pastry")]),
            ]
        ),
        ScriptedChapter(
            title: "names over the speaker", clock: "9:02",
            narration: "9:02. The speaker crackles. The agent reads two names, badly, and one of them is definitely yours.",
            aside: "she's already standing. she's already crying a little.",
            messages: [l("jules"), l("JULES THATS US"), l("wait is it both of us"), l("say its both of us")],
            choices: [
                ScriptedChoice("“it's both of us. window's yours”", replies: [l("I LOVE YOU"), l("i'm writing this down"), l("never again. (again in june)")], outcome: "you caught the 9:15"),
                ScriptedChoice("“you take it. i'll get the 2pm”", replies: [l("no"), l("NO"), l("…ok but i'm buying you a whole cake in new york")], outcome: "you gave Maya the seat"),
                ScriptedChoice("“what if we stay one more night”", replies: [l("i was hoping u would say that"), l("fado round 2"), l("i'll email my boss from the bar")], outcome: "you stayed one more night"),
            ]
        ),
    ], ending: "Lisbon fades into the window. Some trips you take; some trips take you.")

    static let bigSur = ScriptedStory(momentID: "big-sur", speakerID: "maya", chapters: [
        ScriptedChapter(
            title: "highway 1, no bars", clock: "4:15",
            narration: "Somewhere south of Bixby Bridge, the bars go to zero. Maya has the map. Maya does not have the map.",
            aside: "texts are sending at the speed of continental drift.",
            messages: [l("ok so the map is a screenshot"), l("of a different road"), l("but the vibes are correct")],
            choices: [
                ScriptedChoice("“pull over at the next turnout”", replies: [l("the next turnout is a cliff"), l("a gorgeous cliff though")]),
                ScriptedChoice("“follow the vibes”", replies: [l("FINALLY someone gets it"), l("left at the cow")]),
                ScriptedChoice("ask the guy selling avocados", sends: "🥑 he says 9 miles", replies: [l("9 miles of WHAT"), l("buy 6 avocados we're celebrating")]),
            ]
        ),
        ScriptedChapter(
            title: "the campsite that wasn't", clock: "7:48",
            narration: "The reservation is for last August. The ranger is kind about it. The sun is going down like it's late for something.",
            messages: [l("small update"), l("i booked 2018"), l("its 2019"), l("im so sorry. im also laughing")],
            choices: [
                ScriptedChoice("“we sleep in the car. it's fine”", replies: [l("the car smells like avocado"), l("it's PERFECT")], outcome: "you slept in the car, happily"),
                ScriptedChoice("“lmao. lmaooo. ok”", replies: [l("LMAOOO"), l("ok we're the main characters now")], outcome: "you laughed until the stars came out"),
                ScriptedChoice("drive to the motel in Gorda", sends: "📍 gorda, pop. 7", replies: [l("population SEVEN"), l("we'll be 9")], outcome: "you became Gorda's eighth and ninth"),
            ]
        ),
    ], ending: "Zero bars, a whole sky. Nobody posted about it, which is how you know it happened.")

    static let weddingFight = ScriptedStory(momentID: "wedding-fight", speakerID: "maya", chapters: [
        ScriptedChapter(
            title: "the toast", clock: "11:20",
            narration: "Her cousin's wedding. You gave a toast. It had one joke in it too many, and Maya left the tent.",
            aside: "you know exactly which joke.",
            messages: [l("i'm by the cars"), l("don't come out here")],
            choices: [
                ScriptedChoice("go out there anyway", sends: "👟 walking over", replies: [l("i said don't"), l("…bring my shawl")]),
                ScriptedChoice("“i'm sorry. that joke was for me, not you”", replies: [l("yeah"), l("it was")]),
                ScriptedChoice("“it was a JOKE”", replies: [l("ok"), l("goodnight")]),
            ]
        ),
        ScriptedChapter(
            title: "23 days", clock: "9:03",
            narration: "Three weeks of nothing. Her name keeps showing up in your 'recent' list because you keep opening the thread and closing it.",
            messages: [l("hey"), l("i saw a dog that looked like ur toast. bad but trying its best")],
            choices: [
                ScriptedChoice("“i miss you. i was an idiot”", replies: [l("u were"), l("i missed u too"), l("lunch thursday")], outcome: "you said sorry first"),
                ScriptedChoice("send the dog a photo of a worse dog", sends: "📷 a worse dog", replies: [l("LMAOOO"), l("ok we're fine")], outcome: "a worse dog fixed everything"),
                ScriptedChoice("“was it really that bad?”", replies: [l("jules"), l("yes")], outcome: "you learned the toast was that bad"),
            ]
        ),
    ], ending: "The quiet month ends the way quiet months do: with a dog, and lunch on Thursday.")

    static let firstUUp = ScriptedStory(momentID: "first-u-up", speakerID: "maya", chapters: [
        ScriptedChapter(
            title: "fire drill, 2:14 am", clock: "2:14",
            narration: "Sophomore year. The fire alarm in your dorm has been going for ten minutes. A number you don't have saved texts you.",
            messages: [l("u up?"), l("is ur dorm also on fire"), l("this is maya from stats btw")],
            choices: [
                ScriptedChoice("“we're all on the lawn. come find the guy in the cow onesie”", replies: [l("omg"), l("is the cow u"), l("i'm coming")], outcome: "you met Maya in a cow onesie"),
                ScriptedChoice("“who is this”", replies: [l("maya. stats. i sit behind u"), l("ur notes are better than the professor")], outcome: "you started sharing notes"),
                ScriptedChoice("“define 'on fire'”", replies: [l("loudly beeping"), l("emotionally on fire"), l("both")], outcome: "you've been friends since the fire drill"),
            ]
        ),
    ], ending: "Nothing was actually on fire. Everything was, a little.")

    static let berlin = ScriptedStory(momentID: "berlin", speakerID: "maya", chapters: [
        ScriptedChapter(
            title: "berlin hbf", clock: "8:30",
            narration: "Maya's first week at the new job. You're on a train to see her, on a ticket that cost less than your lunch.",
            messages: [l("ur train is late"), l("german trains are never late"), l("unless ur on them apparently")],
            choices: [
                ScriptedChoice("“i'm bringing the pastéis tin”", replies: [l("THE TIN"), l("i'm going to cry at work")], outcome: "you brought Lisbon to Berlin"),
                ScriptedChoice("“how's the job, really”", replies: [l("really?"), l("scary. good scary"), l("tell u at dinner")], outcome: "you heard the real version at dinner"),
                ScriptedChoice("send a photo of the train snack", sends: "📷 one sad pretzel", replies: [l("that pretzel has seen things")], outcome: "you shared a sad pretzel"),
            ]
        ),
    ], ending: "Some people move away so you have somewhere to visit.")

    // MARK: Dad

    static let voiceMemos = ScriptedStory(momentID: "voice-memos", speakerID: "dad", chapters: [
        ScriptedChapter(
            title: "a new feature", clock: "6:40",
            narration: "Dad has discovered voice memos. He has also discovered that he can send them by accident.",
            aside: "you can hear the TV in all of them.",
            messages: [l("🎤 0:47 · voice memo"), l("🎤 0:03 · voice memo"), l("Was that sent. - Dad")],
            choices: [
                ScriptedChoice("“it was sent. all 47 seconds”", replies: [l("Good. Listen to it. - Dad")]),
                ScriptedChoice("“you can just type, dad”", replies: [l("Typing is slow. - Dad"), l("🎤 0:22 · voice memo")]),
                ScriptedChoice("send one back", sends: "🎤 0:05 · “hi dad”", replies: [l("I heard you. Very clear. - Dad")]),
            ]
        ),
        ScriptedChapter(
            title: "the 47 seconds", clock: "6:52",
            narration: "You listen. It's eleven seconds of him finding the button, and thirty-six seconds about the bird feeder.",
            messages: [l("The cardinal came back. - Dad")],
            choices: [
                ScriptedChoice("“send me a picture of the cardinal”", replies: [l("📷 a blur that is probably red"), l("He was fast. - Dad")], outcome: "you got a blurry cardinal"),
                ScriptedChoice("“I love these, keep sending them”", replies: [l("Ok. - Dad"), l("🎤 1:12 · voice memo")], outcome: "you started a voice memo habit"),
                ScriptedChoice("call him instead", sends: "📞 calling Dad…", replies: [l("Why are you calling. - Dad"), l("Kidding. Pick up. - Dad")], outcome: "you called him back"),
            ]
        ),
    ], ending: "Forty-seven seconds about a bird. You saved all of them.")

    static let corolla = ScriptedStory(momentID: "corolla", speakerID: "dad", chapters: [
        ScriptedChapter(
            title: "route 9 shoulder", clock: "3:05",
            narration: "The Corolla, 238,000 miles, has stopped on the shoulder of Route 9 and will not be starting again. Dad is calm. Dad is too calm.",
            aside: "he's had this car longer than he's had you.",
            messages: [l("Car stopped. - Dad"), l("I'm fine. - Dad"), l("Tow truck coming. - Dad")],
            choices: [
                ScriptedChoice("“I'm coming to get you”", replies: [l("No need. - Dad"), l("Ok. Bring coffee. - Dad")]),
                ScriptedChoice("“is it… dead dead?”", replies: [l("Yes. - Dad"), l("She had a good run. - Dad")]),
                ScriptedChoice("send the old photo of you two washing it", sends: "📷 1999, the Corolla, a hose", replies: [l("That was a good day. - Dad")]),
            ]
        ),
        ScriptedChapter(
            title: "the tow yard", clock: "4:40",
            narration: "The tow yard has a cat and a vending machine that only sells root beer. Dad is taking things out of the glovebox one at a time.",
            messages: [l("Found your learner's permit. - Dad"), l("And 3 dollars. - Dad")],
            choices: [
                ScriptedChoice("“keep the permit. split the 3 dollars”", replies: [l("Root beer is 1.50. - Dad"), l("Two root beers. - Dad")], outcome: "you split a root beer with Dad"),
                ScriptedChoice("“want to go look at cars this weekend?”", replies: [l("Not yet. - Dad"), l("Maybe next month. - Dad")], outcome: "you gave the Corolla a month"),
                ScriptedChoice("“tell me about the first time you drove her”", replies: [l("1994. Snowstorm. Your mother drove. - Dad"), l("Long story. Call me. - Dad")], outcome: "you heard the 1994 story"),
            ]
        ),
    ], ending: "Tow receipt: $140. Root beer: $1.50. Glovebox: priceless, apparently.")

    static let dadCooks = ScriptedStory(momentID: "dad-cooks", speakerID: "dad", chapters: [
        ScriptedChapter(
            title: "surgery week, day 2", clock: "5:15",
            narration: "Mom is recovering. Dad, who has never cooked anything that wasn't toast, has decided to make lasagna.",
            aside: "this is how he says he's scared.",
            messages: [l("How long do noodles boil. - Dad"), l("Never mind. They are boiled. - Dad"), l("Very boiled. - Dad")],
            choices: [
                ScriptedChoice("“send me a photo”", replies: [l("📷 a pot of something"), l("It's going well. - Dad")]),
                ScriptedChoice("“dad. how long have they been boiling”", replies: [l("Since 4. - Dad")]),
                ScriptedChoice("call him and walk him through it", sends: "📞 FaceTime, 41 min", replies: [l("Thank you. Don't tell your mother. - Dad")]),
            ]
        ),
        ScriptedChapter(
            title: "the reveal", clock: "7:30",
            narration: "The lasagna comes out. It is not, structurally, lasagna. Mom eats two pieces.",
            messages: [l("She liked it. - Dad"), l("She said so twice. - Dad"), l("📷 an empty plate")],
            choices: [
                ScriptedChoice("“I'm so proud of you”", replies: [l("Ok. - Dad"), l("👍")], outcome: "Dad sent the monthly 👍"),
                ScriptedChoice("“next week: tacos”", replies: [l("Write down the steps. - Dad")], outcome: "you started Dad's recipe binder"),
                ScriptedChoice("“how's Mom, really?”", replies: [l("Better. Tired. Laughing at me. - Dad"), l("Which is good. - Dad")], outcome: "you found out Mom was laughing again"),
            ]
        ),
    ], ending: "Not about the hospital. About a lasagna, and a man who was so proud.")

    // MARK: Priya

    static let moveOut = ScriptedStory(momentID: "move-out", speakerID: "priya", chapters: [
        ScriptedChapter(
            title: "apt 4B, the last box", clock: "10:10",
            narration: "Move-out day. The landlord is coming at noon. The couch does not fit through the door it came in through.",
            aside: "physics is a social construct, according to Priya.",
            messages: [l("babe the couch is STUCK 😭"), l("like half in half out"), l("it's giving schrödinger ✨")],
            choices: [
                ScriptedChoice("“pivot. PIVOT”", replies: [l("PIVOTING 😭😭"), l("ok it moved 1 inch")]),
                ScriptedChoice("“leave it. it lives here now”", replies: [l("omg the next tenant gets a free couch 💅")]),
                ScriptedChoice("bribe the neighbor with bagels", sends: "🥯 x6, delivered", replies: [l("he brought a SAW?? 😳"), l("we're in it now")]),
            ]
        ),
        ScriptedChapter(
            title: "keys on the counter", clock: "11:58",
            narration: "The couch is out (in two pieces). The apartment echoes. Priya is sitting on the floor where the couch was.",
            messages: [l("it looks so small empty 🥺"), l("we had so much life in here"), l("4 years!!")],
            choices: [
                ScriptedChoice("“one last photo”", replies: [l("📸 two idiots on a floor"), l("framing this ✨")], outcome: "you framed the floor photo"),
                ScriptedChoice("“best roommate i'll ever have”", replies: [l("STOP 😭😭"), l("u too babe")], outcome: "you both cried in apt 4B"),
                ScriptedChoice("write your initials inside the closet", sends: "✍️ J+P '18", replies: [l("iconic. historic. illegal? 💅")], outcome: "you left your initials in 4B"),
            ]
        ),
    ], ending: "Apartment 4B, returned to the landlord. Mostly intact. One closet, signed.")

    static let sushi = ScriptedStory(momentID: "sushi", speakerID: "priya", chapters: [
        ScriptedChapter(
            title: "omakase, course 9 of 20", clock: "9:12",
            narration: "Priya's promotion dinner. You said 'my treat' before you saw the menu. The chef is placing a single piece of fish in front of you like it's a ring.",
            aside: "you are doing math under the table.",
            messages: [l("omg this is so fancy 😍"), l("are we allowed to use hands??"), l("u didn't have to do this babe ✨")],
            choices: [
                ScriptedChoice("“you deserve it. order the sake”", replies: [l("ok if u insist 🍶")]),
                ScriptedChoice("“how many courses did he say?”", replies: [l("20!!"), l("isn't that amazing 🥹")]),
                ScriptedChoice("quietly check your bank app", sends: "🏦 balance: humbling", replies: [l("why are u on ur phone, be present 😤")]),
            ]
        ),
        ScriptedChapter(
            title: "the check", clock: "9:41",
            narration: "The check arrives in a small wooden box. It says $214.00. Priya reaches for it.",
            messages: [l("let me split it 🙏"), l("seriously"), l("i literally just got a raise")],
            choices: [
                ScriptedChoice("“no. my treat. that's the whole point”", replies: [l("ok but I'm getting brunch"), l("and it's going to be SO fancy 💅")], outcome: "you paid, and got brunch"),
                ScriptedChoice("“…ok maybe split”", replies: [l("obviously 😂"), l("venmo'd ✨")], outcome: "you split the $214 dinner"),
                ScriptedChoice("“ask him what course 21 is”", replies: [l("JULES NO 😭")], outcome: "you did not find out about course 21"),
            ]
        ),
    ], ending: "Omakase x2, sake, one promotion. Receipt kept, for the scrapbook.")

    // MARK: Theo & the ducks

    static let theoCouch = ScriptedStory(momentID: "theo-couch", speakerID: "theo", chapters: [
        ScriptedChapter(
            title: "week one", clock: "11:30",
            narration: "Between leases, you're on Theo's couch. 'A couple days,' you said. It's been a couple days times seven.",
            messages: [l("bro"), l("u ate my leftovers"), l("its ok. but bro")],
            choices: [
                ScriptedChoice("“I'll restock the fridge”", replies: [l("bet"), l("get the good hummus")]),
                ScriptedChoice("“they were calling to me”", replies: [l("they were MY leftovers"), l("lmao ok")]),
                ScriptedChoice("make him dinner", sends: "🍝 dinner's on", replies: [l("ok u can stay forever")]),
            ]
        ),
        ScriptedChapter(
            title: "week three", clock: "1:02",
            narration: "Your new keys come through. Theo pretends this is fine news and not the end of an era.",
            messages: [l("so ur leaving"), l("cool cool"), l("the couch is gonna be weird w/o u bro")],
            choices: [
                ScriptedChoice("“come over saturday. I'll owe you a couch”", replies: [l("bet. bringing the hummus back")], outcome: "you owe Theo a couch"),
                ScriptedChoice("“thanks for this, really”", replies: [l("dude"), l("anytime. u know that")], outcome: "you said thank you properly"),
                ScriptedChoice("leave a note under the cushion", sends: "📝 IOU: 21 nights", replies: [l("found it. framing it")], outcome: "you left an IOU under the cushion"),
            ]
        ),
    ], ending: "Twenty-one nights on a couch, one friendship upgraded.")

    static let fantasyLeague = ScriptedStory(momentID: "fantasy-league", speakerID: "ducks", chapters: [
        ScriptedChapter(
            title: "the trade", clock: "8:01",
            narration: "Kev has traded his entire roster for a kicker. The ducks are in revolt.",
            aside: "this group chat has 304 moments and 300 of them are this.",
            messages: [l("KEV", "Rafa"), l("explain urself", "Ana"), l("trust the process", "Kev"), l("bro", "theo")],
            choices: [
                ScriptedChoice("“motion to remove kev as commissioner”", replies: [l("SECONDED", "Rafa"), l("this is a coup", "Kev")]),
                ScriptedChoice("“kev what was the process”", replies: [l("vibes", "Kev"), l("😐", "Ana")]),
                ScriptedChoice("send the duck gif", sends: "🦆 [the duck gif]", replies: [l("the duck gif has been deployed", "theo")]),
            ]
        ),
        ScriptedChapter(
            title: "the vote", clock: "9:44",
            narration: "A poll is created. A poll is disputed. A second poll is created about the first poll.",
            messages: [l("final vote. kev stays or goes", "Ana"), l("i would like to address the court", "Kev")],
            choices: [
                ScriptedChoice("“kev stays. punishment: he hosts the draft”", replies: [l("fair", "Rafa"), l("my apartment is 400 sq ft", "Kev")], outcome: "Kev hosted the draft in 400 sq ft"),
                ScriptedChoice("“kev goes. long live the ducks”", replies: [l("🦆🦆🦆", "theo"), l("i'll remember this", "Kev")], outcome: "you overthrew Kev"),
                ScriptedChoice("abstain and mute the chat", sends: "🔕 muted for 8 hours", replies: [l("jules muted us", "Ana"), l("respect", "Rafa")], outcome: "you muted the ducks (and survived)"),
            ]
        ),
    ], ending: "The mutiny is over. The kicker scored 2 points. Nobody has forgotten.")

    static let theo30th = ScriptedStory(momentID: "theo-30th", speakerID: "ducks", chapters: [
        ScriptedChapter(
            title: "the plan", clock: "6:30",
            narration: "Theo's 30th, a warehouse in Bushwick, a surprise he definitely knows about. You're in charge of the cake.",
            aside: "you are not a cake person.",
            messages: [l("who has the cake", "Ana"), l("jules has the cake", "Rafa"), l("jules do u have the cake", "Kev")],
            choices: [
                ScriptedChoice("“I have the cake”", replies: [l("do u though", "Ana")]),
                ScriptedChoice("“define cake”", replies: [l("JULES", "Rafa"), l("oh no", "Kev")]),
                ScriptedChoice("send a photo of the cake", sends: "📷 a cake that says ‘HAPPY 3OTH’", replies: [l("3OTH", "Ana"), l("it's perfect dont change it", "Rafa")]),
            ]
        ),
        ScriptedChapter(
            title: "surprise", clock: "10:15",
            narration: "Lights off. Theo walks in. Everyone yells. Theo does his best surprised face, which is his regular face.",
            messages: [l("bro", "theo"), l("BRO", "theo"), l("who made the 3OTH cake. i love it", "theo")],
            choices: [
                ScriptedChoice("“happy 3oth, theo”", replies: [l("best birthday ever. 3oth forever", "theo")], outcome: "3OTH became a ducks holiday"),
                ScriptedChoice("“it was ana's idea”", replies: [l("IT WAS NOT", "Ana"), l("😂😂", "Rafa")], outcome: "you blamed Ana for the cake"),
                ScriptedChoice("start the speech", sends: "🎤 “ok everyone, about theo…”", replies: [l("dont make me cry in bushwick", "theo")], outcome: "you made Theo cry in Bushwick"),
            ]
        ),
    ], ending: "ADMIT ONE. Bushwick, a warehouse, a cake with a typo you'll never fix.")
}
