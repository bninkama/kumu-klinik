# Kumu Klinic — 3-Minute Demo Script

**Total: ~3:00. Record on an Android phone in landscape or portrait. Have a
cocoa pod photo (diseased) ready on a second device or printed — search
"cocoa black pod Phytophthora" for a good sample image.**

## 0:00–0:20 — The problem

> "Papua New Guinea has 2 million smallholder farmers. When a cocoa pod turns
> black, most can't reach an agriculture officer — many can't read English
> extension leaflets either. Kumu Klinic puts a Tok Pisin-speaking
> agronomist in their pocket, powered by Gemini."

Show the app home screen. Point out the big green button, Tok Pisin UI,
weather alert card.

## 0:20–1:10 — Diagnosis

> "Watch. I take a photo of this sick cocoa pod—" *(tap TEKIM PIKSA, snap
> photo of sample image)* "—Gemini 2.0 Flash Vision identifies the disease
> in about five seconds."

Show loading "Gemini i luklukim sik..." then the result card:

> "Black Pod — 92% confident. And here's the key: the advice isn't just in
> English." *(tap Tok Pisin tab, then the speaker button)*

Let TTS play ~10 s of Tok Pisin advice. Highlight the three action cards:
Wokim nau / Marasin / Blom bihain.

## 1:10–1:50 — Offline mode

Turn on airplane mode **live on camera**.

> "Now the reality of PNG: no signal in the village." *(airplane mode on)*
> "The disease library still works—" *(open Library, tap Taro Leaf Blight,
> show symptoms + treatment in Tok Pisin)* "—and if I take another photo,
> it queues for upload when the network returns." *(snap photo, show
> 'Piksa i seiv' message)*

Airplane mode off.

## 1:50–2:20 — Weather & market

> "Farmers also plan around rain and prices." Open Weather & Prices tab.
> "Morobe: heavy rain in 2 days — time to harvest ripe pods now. And cocoa
> wet bean is K5/kg in Lae, parchment coffee K15 in Goroka."

## 2:20–3:00 — Tech close + impact

> "Under the hood: Flutter on the phone, Express on Cloud Run, Gemini 2.0
> Flash Vision for diagnosis, Firestore for the disease library, and a
> Gemma 2B on-device fallback for offline Tok Pisin. Everything runs on
> Google Cloud."

Show architecture diagram for ~10 s.

> "Kumu Klinic means earlier disease detection, less crop loss, and advice
> in a language farmers actually speak. Kumu i stap gut — tenkyu tru."

## Sample images to prepare

- Diseased cocoa pod with black lesions (Black Pod)
- Cocoa pod with borer holes (Cocoa Pod Borer)
- Coffee leaf with orange underside spots (Leaf Rust)
- A non-crop photo (e.g., a shoe) to show the `not_crop` response
