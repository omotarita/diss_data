breed [ collections collection ]
breed [ traders trader ]

collections-own [
  num-sales discovered?
  collection-tweet-count
  num-tweets
  num-tweets-period
  num-tweets-hour
  traders-inspecting-collection
  num-sales-period-f
  num-sales-period-i
]
traders-own [

  my-home          ; a person's original position
  next-task        ; the code block a person is running
  task-string      ; the behavior a person is displaying
  person-timer     ; a timer keeping track of the length of the current state
                   ;   or the waiting time before entering next state
  target           ; the collection that a person is currently focusing on exploring
  interest         ; a person's interest in the target collection
  z-interest       ; normalised interest
  trips            ; times a person has visited the target

  initial-trader?   ; true if it is an initial trader, who explores the unknown horizons
  no-discovery?    ; true if it is an initial trader and fails to discover any collection collection
                   ;   on its initial exploration
  inspecting-collection?         ; true if it's inspecting a collection
  tweeting?        ; tbc
  watching-tweet? ; tbc
  informed?        ; true if the trader is informed


  ; tweet related variables:

  dist-to-collection     ; the distance between the network and the collection that a person is exploring
  circle-switch    ; when making a tweet, a person alternates left and right to make
                   ;   the figure "8". circle-switch alternates between 1 and -1 to tell
                   ;   a person which direction to turn.
  temp-x-tweet     ; initial position of a tweet
  temp-y-tweet
  ;sphere-of-influence    ; a radius which corresponds to the scope of a trader's reach within the
                         ; network
  interaction-circle     ; a radius which corresponds to the scope of a trader's vision of what is
                         ; happening within the network
  susceptibility; the influence an NFT-related tweet has on a person. how sensitive a person is to being influenced by NFT noise
  tweet-sum        ; the number of tweets in a person's vicinity about their selected target
  influence       ; a person's influence on others' decisions
  confidence   ; a person's confidence in their financial predictions, 0 for uninformed traders


]

globals [
  color-list       ; colors for collections, which keeps consistency among the collection colors, plot
                   ;   pens colors, and committed people's colors
  num-sales-list     ; num-sales of collections
  network-radius     ; radius of network
  initial-explore-time ; initial-explore-time
  collection-number      ; number of collections
  sim-round             ; the rounds of the simulation
  sales-performance     ;

  early-adopters   ; number of early adopters
  uninformed-traders  ; number of uninformed traders
  informed-traders ; number of informed traders
  interest-to-tweet ; interest level at which they would tweet
  interest-to-buy   ; interest level at which they would buy
  occupation       ; tbc
  sales            ; tbc
  tweets           ; tbc
  ticks-per-day    ; tbc: number of ticks per day
  period           ; tbc: given time period -- remember to justify the time period chosen
  sim-timer     ;
  hourly-timer     ;
  hour-counter     ; tbc: counts hours passed
  days             ; tbc: number of days passed
  stagger          ; tbc: stagger between seeing tweets and exploring collection
  show-tweet-path? ; tweet path is the circular patter with a zigzag line in the middle.
                   ;   when large amount of people tweet, the patterns overlaps each other,
                   ;   which makes them hard to distinguish. turn show-tweet-path? off can
                   ;   clear existing patterns
  traders-visible?  ; you can hide traders and only look at the tweet patterns to avoid
                   ;   distraction from people's tweeting movements
  clear?           ; should we clear drawing?
  watch-tweet-task ; a list of tasks
  discover-task
  inspect-collection-task
  go-home-task
  tweet-task
  re-visit-task
]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;setup;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to setup
  clear-all
  set network-radius 4
  setup-collections
  setup-tasks
  setup-people
  set initial-explore-time 300
  set collection-number 6
  set show-tweet-path? true
  set traders-visible? true
  set interest-to-tweet 0.2
  set interest-to-buy 0.40
  set ticks-per-day 1000
  set period ticks-per-day 
  set sim-timer 0
  set hourly-timer 0
  set hour-counter 0
  set days 1
  set sim-round 1
  set stagger ticks-per-day / 24 
  reset-ticks
end

to setup-collections
 let collection-count length read-from-string list-collections-sales-f
 set sales-performance []
 let c 0
 set color-list []
 while [c < collection-count]
 [
  let colour-code one-of (range 11 140)
  while [colour-code mod 10 = 0] [
     set colour-code one-of (range 11 140)
   ]
  let colour colour-code
  let index length color-list
  set color-list insert-item index color-list colour
  set c c + 1
 ]
 set collection-number collection-count
 ask n-of collection-count patches with [
   distancexy 0 0 = 20 and abs pxcor < (max-pxcor - 2) and
   abs pycor < (max-pycor - 2)
 ] [
   sprout-collections 1 [
     set shape "hex"
     set size 2
     set color gray
     set discovered? false
   ]
 ]
 let i 0
 repeat count collections [
   ask collection i [
     set num-sales item i read-from-string list-collections-sales-f
     set num-sales-period-f item i read-from-string list-collections-sales-f
     set num-sales-period-i item i read-from-string list-collections-sales-i
     set collection-tweet-count item i read-from-string list-collections-tweets
     set label num-sales
     set sales-performance insert-item i sales-performance num-sales-period-f
     set num-tweets 0
     set num-tweets-period 0
     set num-tweets-hour 0
     set num-sales-period-f 0

   ]
   set-current-plot "Number of Sales"
   create-temporary-plot-pen word "collection" i
   set-plot-pen-color item i color-list
   set-current-plot "committed"
   create-temporary-plot-pen word "target" i
   set-plot-pen-color item i color-list
   set-current-plot "Collections: t/s"
   create-temporary-plot-pen word "tweets/sales" i
   set-plot-pen-color item i color-list
   set i i + 1
 ]
end

to-report random-normal-in-bounds [mid dev mmin mmax]
  let result random-normal mid dev
  if result < mmin or result > mmax
    [ report random-normal-in-bounds mid dev mmin mmax ]
  report result
end

to setup-people
  let influence-dist n-values 1000 [ random-normal-in-bounds 0.00169 0.00683288409 0 0.169 ]
  set influence-dist sort influence-dist
  let dex 0
  create-traders 1000 [
    fd random-float network-radius
    set my-home patch-here
    set shape "person"
    set color gray
    set initial-trader? false
    set target nobody
    set circle-switch 1
    set no-discovery? false
    set inspecting-collection? false
    set tweeting? false
    set watching-tweet? false
    set next-task watch-tweet-task
    set task-string "watching-tweet"
    set informed? false
    set susceptibility random-normal 0.5 0.2
    set interaction-circle sqrt ((random-normal 0.002 0.014) ^ 2)
    ;set sphere-of-influence random-normal 1 0.75
    ifelse dex < (1000 - ((informed-percentage / 100) * 1000)) [
      set influence item dex influence-dist
    ][
      set dex 0
      set influence item dex influence-dist
    ]
    set confidence 0
    set interest 0
    set z-interest 0
    set dex dex + 1
  ]
  set early-adopters (0.08) * (count traders) 
  ask n-of early-adopters traders [
    set initial-trader? true 
    set person-timer 5 
  ]

  set informed-traders (informed-percentage / 100) * (count traders)
  set dex (1000 - ((informed-percentage / 100) * 1000))
  ask n-of informed-traders traders [
    set informed? true
    set susceptibility 0
    ifelse dex < 1000 [
      set influence item dex influence-dist
    ][
      set dex (1000 - ((informed-percentage / 100) * 1000))
      set influence item dex influence-dist
    ]
    set confidence random-normal 0.5 0.2
    set dex dex + 1
  ]


end

to setup-tasks
  watch-tweet
  discover
  inspect-collection
  go-home
  tweet
  re-visit
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;watch-tweet;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to watch-tweet
 set watch-tweet-task [ ->
   move-around ;?
   if initial-trader? and person-timer < 0 [
     set next-task discover-task
     set task-string "discovering"
     set person-timer initial-explore-time
     set initial-trader? true
   ]
   if not initial-trader? [
     if person-timer < 0 [
       set watching-tweet? true
       if sim-round > 1 and count other traders in-cone interaction-circle 360 > 0 [
         let focus one-of other traders in-cone interaction-circle 360 with [next-task != discover-task]
         if random 2 = 1 [
           let temp-focus one-of other traders in-cone interaction-circle 360 with [next-task = tweet-task]
           if temp-focus != nobody [set focus temp-focus]
         ]
         if focus != nobody and [target] of focus != nobody [
         let my-target [target] of focus
         let community other traders in-cone interaction-circle 360 with [target = my-target]
         set target my-target
         set tweet-sum count community
         let i 0 
         let tweet-product-sum 0
          ask community [
           let tweet-product (interest * influence) ;impact x influence = strength
           set tweet-product-sum tweet-product-sum + tweet-product ; total strength
           ]
           let community-strength tweet-product-sum / tweet-sum ; avg strength

           let difference 1 
           ifelse [num-sales-period-i] of target = 0
           [
             set difference sqrt ((([num-sales-period-f] of target - 1) / 1) ^ 2 )
           ][
             set difference sqrt ((([num-sales-period-f] of target - [num-sales-period-i] of target) / [num-sales-period-i] of target) ^ 2 )
           ]
            let interpretation 0.001
            let social-impact 0.001

            if difference != 0 [set interpretation (ln(difference / 122.17)) / (ln(0.67))]
            if tweet-sum != 0 [set social-impact (ln((community-strength * tweet-sum) / 0.016870)) / (ln(316.2270))]
           set interest sqrt( ((susceptibility * social-impact) + (confidence * interpretation)) ^ 2 )

           ifelse not informed?[
             let interest-dist [interest] of traders with [interest > 0 and not informed?]
             ifelse length (interest-dist) > 2 [
             let mu ( mean interest-dist ) 
             let sigma ( standard-deviation interest-dist )
             if mu != 0 and sigma != 0 [
             set z-interest ((interest - mu ) / sigma )
              if interest > interest-to-buy [
               set color white
               set next-task re-visit-task
               set task-string "revisiting"
               set person-timer stagger
               set watching-tweet? false
              ]
             ]
            ][
               set next-task watch-tweet-task
               set task-string "watching-tweet"
             ]
           ][
             let interest-dist [interest] of traders with [interest > 0 and informed?] ; interest > 0 and
             ifelse length (interest-dist) > 2 [
             let mu ( mean interest-dist )
             let sigma ( standard-deviation interest-dist )
             if mu != 0 and sigma != 0 [
             set z-interest ((interest - mu ) / sigma )
              if interest > interest-to-buy [                        
               set color white
               set next-task re-visit-task
               set task-string "revisiting"
               set person-timer stagger
               set watching-tweet? false
              ]
             ]
            ][
               set next-task watch-tweet-task
               set task-string "watching-tweet"
             ]
           ]

         ]
       ]
     ]
   ]
   set person-timer person-timer - 1
 ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;discover;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to discover
 set discover-task [ ->
   ifelse person-timer < 0 [
     set next-task go-home-task
     set task-string "going-home"
     set no-discovery? true
     set initial-trader? false
   ]
   [
     ifelse count collections in-radius 20 != 0 [
       let temp-target one-of collections in-radius 20
       ask temp-target [
         set occupation count traders with [target = temp-target]
         ifelse occupation != 1[
         type temp-target type " is targeted by " type occupation print " people."
         ][
         type temp-target type " is targeted by " type occupation print " person."
         ]

       ]
       ifelse occupation >= (early-adopters / collection-number) [
         rt (random 60 - random 60) proceed
         set person-timer person-timer - 1
       ]
       [
         set target temp-target
					;let i 0
         ask target [
           set discovered? true
           set color item who color-list
         ]
         set color [ color ] of target
         set next-task inspect-collection-task
         set task-string "inspecting-collection"
         set person-timer 100


       ]
     ] [
       rt (random 60 - random 60) proceed
     ]
     set person-timer person-timer - 1
   ]
 ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;inspect-collection;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to inspect-collection
 set inspect-collection-task [ ->
   ifelse person-timer < 0 [
     ifelse not initial-trader? [
     set interest interest ^ -1.4 ; interest decline following power law function s^b where b = -1.4
     ask target [
           set num-sales num-sales + 0.5
           set num-sales-period-f num-sales-period-f + 0.5
           set label round num-sales
      ]
     ][
       set tweet-sum [collection-tweet-count] of target
       let difference sqrt ((([num-sales-period-f] of target - [num-sales-period-i] of target) / [num-sales-period-i] of target) ^ 2)
        let interpretation 0.001
        let tweet-impact 0.001

        if difference != 0 [set interpretation (ln(difference / 122.17)) / (ln(0.67))]
        if tweet-sum != 0 [set tweet-impact (ln(tweet-sum / 0.732)) / (ln(509.44))]

       set interest sqrt( ((susceptibility * tweet-impact) + (confidence * interpretation)) ^ 2 )

       ifelse not informed?[
           let interest-dist [interest] of traders with [interest > 0 and not informed?]
           if length (interest-dist) > 2 [
           let mu ( mean interest-dist )
           let sigma ( standard-deviation interest-dist )
           if mu != 0 and sigma != 0 [
           set z-interest ((interest - mu ) / sigma )
           ]
         ]
       ][
           let interest-dist [interest] of traders with [interest > 0 and informed?]
           if length (interest-dist) > 2 [
           let mu ( mean interest-dist )
           let sigma ( standard-deviation interest-dist )
           if mu != 0 and sigma != 0 [
           set z-interest ((interest - mu ) / sigma )
           ]
         ]
       ]
     ]
     set my-home patch random-float (network-radius) random-float (network-radius)
     set next-task go-home-task
     set task-string "going-home"
     set inspecting-collection? false
     set initial-trader? false
     set trips trips + 1
   ] [
     if distance target > 2 [
       face target fd 1
     ]
     set inspecting-collection? true
     let nearby-traders traders with [ inspecting-collection? and target = [ target ] of myself ] in-radius 3
     ifelse random 3 = 0 [ hide-turtle ] [ show-turtle ]
     set dist-to-collection distancexy 0 0
     set person-timer person-timer - 1
   ]
 ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;go-home;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to go-home
  set go-home-task [ ->
    ifelse distance my-home < 1 [
      ifelse no-discovery? [
        set next-task watch-tweet-task
        set task-string "watching-tweet"
        set no-discovery? false
        set initial-trader? false
      ] [
          set next-task tweet-task
          set task-string "tweeting"
          set person-timer 30 + (random (100 - 30))
      ]
    ] [
      while [distance my-home > 1] [
      face my-home proceed
      ]
    ]
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;tweet;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to tweet
 set tweet-task [ ->
   pen-up
   set heading random (360 - 0)
   set sim-round 2
   if distance my-home > 0.2 [
     while [distance my-home > 0.2] [
     face my-home proceed
     ]
   ]
   if target = nobody [
     set next-task watch-tweet-task
     set task-string "watching-tweet"
     set tweeting? false
     pen-up
     set watching-tweet? true
   ]
   if person-timer <= 0 [
    ifelse interest < interest-to-buy [
      set next-task watch-tweet-task
      set task-string "watching-tweet"
      set tweeting? false
      pen-up
      set watching-tweet? true
     ][
      set next-task re-visit-task
      set task-string "revisiting"
      set tweeting? false
      pen-up
      set interest interest ^ -1.4
     ]
   ]
                        
   if interest <= interest-to-tweet [
     set next-task watch-tweet-task
     set task-string "watching-tweet"
     set tweeting? false
     pen-up
     set watching-tweet? true
     set trips 0
     set color gray
     set person-timer one-of (range 15 105)
   ]
     ifelse show-tweet-path? [pen-down][pen-up]
     repeat 1 [
      waggle
      make-semicircle
      set clear? true
     ]
     pen-up
     set person-timer person-timer - 4
 ]
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;re-visit;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to re-visit
  set re-visit-task [ ->
    set tweeting? false
    pen-up
    ifelse person-timer > 0 [
      set person-timer person-timer - 1
    ] [
      ifelse distance target < 1 [
        set color [ color ] of target
        if interest = 0 [ 
          set interest [ num-tweets-period ] of target 
        ]
        set next-task inspect-collection-task
        set task-string "inspecting-collection"
        set person-timer one-of (range 35 65)
      ] [
        proceed
        face target
      ]
    ]
  ]
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;run-time;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to go
  set clear? false
	(ifelse
    ticks < 7 * ticks-per-day [
    	ask traders [ run next-task ]
    	plot-inspecting-collection-traders
      plot-tweet-sales
      tick
      set sim-timer sim-timer + 1
      set hourly-timer hourly-timer + 1
      if clear? [ clear-drawing ]
      if sim-timer > period [
        set sales-performance []
        set sim-timer 0
        print "Period has lapsed. Timer reset"
        type "Day " type days print " has passed, with the following results:"
        let n 0
        repeat count collections [
          while [n < count collections] [
            ask collection n [
            type "Collection " type n type ":" print round num-sales-period-f
            set sales-performance insert-item n sales-performance num-sales-period-f
            set num-sales-period-i num-sales-period-f
            set num-sales-period-f 0
          ]
          set n n + 1
         ]
        ]
        set days days + 1
      ]
    ]
		[
    stop
  ])
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;utilities;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to make-semicircle
  if interest > 1 [
  let num-of-turns 1 / interest * 2600
  let angle-per-turn 180 / num-of-turns
  let semicircle 0.5 * dist-to-collection * pi / 5
  if circle-switch = 1 [
    face target lt 90
    repeat num-of-turns [
      lt angle-per-turn
      fd (semicircle / 180 * angle-per-turn)
    ]
  ]
  if circle-switch = -1 [
    face target rt 90
    repeat num-of-turns [
      rt angle-per-turn
      fd (semicircle / 180 * angle-per-turn)
    ]
   ]
  ]
  set circle-switch circle-switch * -1
  setxy temp-x-tweet temp-y-tweet
end

to waggle
  face target
  set temp-x-tweet xcor set temp-y-tweet ycor
  let waggle-switch 1
  lt 60
  fd .4
  ; correlates the number of turns in the zigzag line with the distance
  ; between the network and the collection. the number 2 is selected by trial
  ; and error to make the tweet path look clear (Guo and Wilensky, 2014)
  repeat (dist-to-collection - 2) / 2 [
    if waggle-switch = 1 [rt 120 fd .8]
    if waggle-switch = -1 [lt 120 fd .8]
    set waggle-switch waggle-switch * -1
  ]
  ifelse waggle-switch = -1 [lt 120 fd .4][rt 120 fd .4]
end

to proceed
  rt (random 20 - random 20)
  if not can-move? 1 [ rt 180 ]
  fd 0.2
end

to move-around
  rt (random 60 - random 60) fd random-float .1
  if distancexy 0 0 > 4 [facexy 0 0 fd 1]
end

to plot-inspecting-collection-traders
  let i 0
  repeat count collections [
    set-current-plot "Number of Sales"
    set-current-plot-pen word "collection" i
    ask collection i[
    set sales num-sales
    ]
    plot sales
    set-current-plot "committed"
    set-current-plot-pen word "target" i
    plot count traders with [target = collection i]

    set i i + 1
  ]
end

to plot-tweet-sales
  let i 0
  repeat count collections [
    set-current-plot "Collections: t/s"
    set-current-plot-pen word "tweets/sales" i
    ask collection i[
    set sales num-sales
    set tweets num-tweets
    ]
    plotxy tweets sales
    set i i + 1
  ]
end

to show-hide-tweet-path
  if show-tweet-path? [
    clear-drawing
  ]
  set show-tweet-path? not show-tweet-path?
end

to show-hide-traders
  ifelse traders-visible? [
    ask traders [hide-turtle]
  ]
  [
    ask traders [show-turtle]
  ]
  set traders-visible? not traders-visible?
end

; Copyright 2014 Uri Wilensky and 2022 Omotara Edu
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
370
10
1093
558
-1
-1
11.0
1
10
1
1
1
0
0
0
1
-32
32
-24
24
0
0
1
ticks
120.0

BUTTON
1105
435
1245
471
Setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
1105
490
1245
525
Go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

SLIDER
5
420
355
453
informed-percentage
informed-percentage
0
25
2.0
0.4
1
%
HORIZONTAL

PLOT
1102
222
1412
426
Number of Sales
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS

PLOT
1102
10
1412
222
committed
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS

BUTTON
1265
435
1405
471
Show/Hide Tweet Path
show-hide-tweet-path
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

BUTTON
1265
490
1412
523
Show/Hide Traders
show-hide-traders
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

PLOT
1455
35
1845
370
Collections: t/s
tweets
sales
0.0
10.0
0.0
10.0
true
false
"" ""
PENS

INPUTBOX
10
85
350
145
list-collections-sales-f
[4 6 1 3 7 3 12 6 6 14]
1
0
String

TEXTBOX
25
240
350
376
For the three input boxes above, list the sales/tweet counts for all collections you want to simulate following this format:\n\n[10 11 29 82 49 etc.]\n\nMake sure you use square brackets!
11
0.0
1

INPUTBOX
10
155
350
215
list-collections-tweets
[1 2 3 4 5 6 7 8 9 10]
1
0
String

INPUTBOX
10
15
350
75
list-collections-sales-i
[1 2 3 4 5 6 7 8 9 10]
1
0
String

@#$#@#$#@
## WHAT IS IT?

The NFT Tracker model aims to display the herding behaviours underpinning the NFT market. (shows the swarm intelligence of honeybees during their hive-finding process). A swarm of tens of thousands of honeybees can accurately pick the best new hive site available among dozens of potential choices through self-organizing behavior.

The mechanism in this model is based on Honeybee Democracy (Seeley, 2010) with some modifications and simplifications. One simplification is that this model only shows scout bees—a 3-5% population of the whole swarm that is actively involved in the decision making process. Other bees are left out because they simply follow the scouts to the new hive when a decision is made. Leaving out the non-scouts reduces the computational load and makes this model visually clearer.

This model is also the first of a series of models in a computational modeling-based scientific inquiry curricular unit “BeeSmart”, designed to help high school and university students learn complex systems principles as crosscutting concepts in science learning. Subsequent models are coming soon.

## HOW IT WORKS

At each SETUP, 100 scout bees are placed at the center of the view. Meanwhile, a certain number (determined by the “hive-number” slider) of potential hive sites are randomly placed around the swarm.

On clicking GO, initial scouts (the proportion of which are determined by the “initial-percentage” slider) fly away from the swarm in different directions to explore the surrounding space. They will explore the space for a maximum of “initial-explore-time.” If one scout stumbles upon a potential hive site, she inspects it. Otherwise, she goes back to the swarm and remains idle.

When a scout discovers a potential hive site, she inspects it to learn its location, color, and quality. Then she flies back to the swarm to advertise the site through waggle dances. The better the quality of the hive, the longer the scouts dance, the easier these dances are seen by idle bees in the swarm, and the more likely idle bees follow the dances to inspect the advertised hive site. After a newly joined bee’s inspection of the advertised site, the new bee flies back to the swarm and expresses her own opinions about the site through waggle dances. Bees revisit the sites they advocated, but their interests in the site decline after each revisit. Advertising for different sites continues in parallel in the swarm, but high quality sites attract more and more bees while low quality ones are gradually ignored.

When bees on a certain hive site observe a certain number of bees on the same site, or, in other words, when the “quorum” is reached, they fly back to the swarm and start to “pipe” to announce that a decision has been made. Any bee that hears the piping will also pipe, which causes the piping to spread across the swarm quickly. When all the bees are piping, the whole swarm takes off to move to the winning hive site and the model stops.

Typically, an initial scout goes through the states of “discover”-> “inspect-hive”-> “go-home”-> “dance”-> “re-visit”-> “pipe”; and non-initial scouts follow a slightly different sequence of states: “watch-dance”-> “re-visit” -> “inspect-hive”-> “go-home”-> “dance”-> “re-visit”-> “pipe”.

## HOW TO USE IT

Use the sliders to define the initial conditions of the model. The default values usually guarantee a successful hive finding, but users are encouraged to change these settings and see how each parameter affects the process.

Click SETUP after setting the parameters by the sliders. Then click GO and observe how the phenomenon unfolds. Toggle the “Show/Hide Dance Path” button to show or hide the waggle dance paths. Use the “Show/Hide Scouts” button to hide the bees if they block your view of the dance paths.

## THINGS TO NOTICE

Notice the three plots on the right hand of the model:

The “committed” plot shows the number of scouts that are committed to inspecting and advocating for each hive site; The “on-site” plot shows the count of bees on each site; The “watching vs. working” plot shows the change in numbers of idle and working bees.

Observe how information about multiple sites is brought to the swarm at the center of the view and how preference of the swarm changes over time.

Notice whether the timing of discovering the best hive site affects the swarm’s decision.

Zoom in and compare the “enthusiasm” of dances for high quality sites with those for low quality ones. Bees not only dance longer but also more enthusiastically (or faster, in this model, when they are making turns) for higher quality sites.

## THINGS TO TRY

Right click any scout and choose “Watch” from the right-click menu. A halo would appear around the scout to help you keep track of its movement.

Set sliders to different values and observe how these parameters affect the dynamic of the process.

Use the speed slider at the top of the model to slow down the model and observe the waggle dances.

Use “Control +” or “Command +” to zoom in and see the colors of the bees.

## EXTENDING THE MODEL

This model shows the honeybees’ hive-finding phenomenon as a continuous process. However, in reality, this process may last a few days. Bees do rest over night. Weather conditions may also affect this process. Adding these factors to the model can make it more accurately represent the phenomenon in the real world.

Currently, Site qualities cannot be controlled from the interface. Some input interface elements can be added to enable users to specify the quality of each hive.

## NETLOGO FEATURES

This model is essentially a state machine. Bees behave differently at different states. Command tasks are heavily used in this model to simplify the shifts between states and to enhance the performance of the model.

The pens in the plots are dynamically generated temporary plot pens, which match the number of hive sites that are determined by users.

The dance patterns are dynamically generated, which show the direction, distance, and quality of the hive advertised.

## RELATED MODELS

Guo, Y. & Wilensky, U. (2014). NetLogo BeeSmart model. http://ccl.northwestern.edu/netlogo/models/BeeSmartHiveFinding. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Wilensky, U. (1997). NetLogo Ants model. http://ccl.northwestern.edu/netlogo/models/Ants. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Wilensky, U. (2003). NetLogo Honeycomb model. http://ccl.northwestern.edu/netlogo/models/Honeycomb. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## CREDITS AND REFERENCES

Seeley, T. D. (2010). Honeybee democracy. Princeton, NJ: Princeton University Press.

Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University. Evanston, IL.

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Edu, O. (2022).  NetLogo NFT Market model.  http://ccl.northwestern.edu/netlogo/models/NFTMarket.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 2022 Omotara Edu.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

<!-- 2022 Cite: Edu, O. -->
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

bee
true
0
Polygon -1184463 true false 152 149 77 163 67 195 67 211 74 234 85 252 100 264 116 276 134 286 151 300 167 285 182 278 206 260 220 242 226 218 226 195 222 166
Polygon -16777216 true false 150 149 128 151 114 151 98 145 80 122 80 103 81 83 95 67 117 58 141 54 151 53 177 55 195 66 207 82 211 94 211 116 204 139 189 149 171 152
Polygon -7500403 true true 151 54 119 59 96 60 81 50 78 39 87 25 103 18 115 23 121 13 150 1 180 14 189 23 197 17 210 19 222 30 222 44 212 57 192 58
Polygon -16777216 true false 70 185 74 171 223 172 224 186
Polygon -16777216 true false 67 211 71 226 224 226 225 211 67 211
Polygon -16777216 true false 91 257 106 269 195 269 211 255
Line -1 false 144 100 70 87
Line -1 false 70 87 45 87
Line -1 false 45 86 26 97
Line -1 false 26 96 22 115
Line -1 false 22 115 25 130
Line -1 false 26 131 37 141
Line -1 false 37 141 55 144
Line -1 false 55 143 143 101
Line -1 false 141 100 227 138
Line -1 false 227 138 241 137
Line -1 false 241 137 249 129
Line -1 false 249 129 254 110
Line -1 false 253 108 248 97
Line -1 false 249 95 235 82
Line -1 false 235 82 144 100

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

hex
false
0
Polygon -7500403 true true 0 150 75 30 225 30 300 150 225 270 75 270

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.2.2
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="Dissertation" repetitions="5" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>ticks &gt; 7000</exitCondition>
    <metric>[num-sales-period] of collections</metric>
    <steppedValueSet variable="initial-percentage" first="0" step="10" last="100"/>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
1
@#$#@#$#@
