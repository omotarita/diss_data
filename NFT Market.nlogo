breed [ collections collection ]
breed [ scouts scout ]

collections-own [
  num-sales discovered?
  num-tweets
  num-tweets-period
  num-tweets-hour
  scouts-inspecting-collection
]
scouts-own [

  my-home          ; a person's original position
  next-task        ; the code block a person is running
  task-string      ; the behavior a person is displaying
  person-timer     ; a timer keeping track of the length of the current state
                   ;   or the waiting time before entering next state
  target           ; the collection that a person is currently focusing on exploring
  interest         ; a person's interest in the target collection
  trips            ; times a person has visited the target

  initial-scout?   ; true if it is an initial scout, who explores the unknown horizons
  no-discovery?    ; true if it is an initial scout and fails to discover any collection collection
                   ;   on its initial exploration
  inspecting-collection?         ; true if it's inspecting a collection
  tweeting?        ; tbc
  watching-tweet? ; tbc

  ; tweet related variables:

  dist-to-collection     ; the distance between the network and the collection that a person is exploring
  circle-switch    ; when making a tweet, a person alternates left and right to make
                   ;   the figure "8". circle-switch alternates between 1 and -1 to tell
                   ;   a person which direction to turn.
  temp-x-tweet     ; initial position of a tweet
  temp-y-tweet
  sphere-of-influence    ; a radius which corresponds to the scope of a scout's reach within the
                         ; network
  interaction-circle     ; a radius which corresponds to the scope of a scout's vision of what is
                         ; happening within the network
]

globals [
  color-list       ; colors for collections, which keeps consistency among the collection colors, plot
                   ;   pens colors, and committed people's colors
  num-sales-list     ; num-sales of collections
  ;probability      ; the decision-making influence probability
  initial-explore-time ; initial-explore-time
  collection-number      ; number of collections
  ;collection-timer       ; a timer keeping track of the days elapsed at a collection

  ; visualization:
  early-adopters   ; number of early adopters
  occupation       ; tbc
  sales            ; tbc
  tweets           ; tbc
  ticks-per-day    ; tbc: number of ticks per day
  period           ; tbc: given time period -- remember to justify the time period chosen
  period-timer     ;
  hourly-timer     ;
  hour-counter     ; tbc: counts hours passed
  days             ; tbc: number of days passed
  stagger          ; tbc: stagger between seeing tweets and exploring collection
  show-tweet-path? ; tweet path is the circular patter with a zigzag line in the middle.
                   ;   when large amount of people tweet, the patterns overlaps each other,
                   ;   which makes them hard to distinguish. turn show-tweet-path? off can
                   ;   clear existing patterns
  scouts-visible?  ; you can hide scouts and only look at the tweet patterns to avoid
                   ;   distraction from people's tweeting movements
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
  setup-collections
  setup-tasks
  setup-people
  set initial-explore-time 300
  set collection-number 6
  ;set collection-number 5
  set show-tweet-path? true
  set scouts-visible? true
  set ticks-per-day 500
  set period (1 / 24) * ticks-per-day ; assuming 1/24 day (1/24 represents days)
  set period-timer 0
  set hourly-timer 0
  set hour-counter 0
  set days 1
  set stagger ticks-per-day / 24 ; assuming 1 hour (1/24 represents hours)
  reset-ticks
end

to setup-collections
  set color-list [ 97.9 57.5 17.6 27.5 117.9 114.4 ]
  ;set color-list [ 97.9 57.5 17.6 27.5 117.9 ]
  set num-sales-list (list sales-a sales-b sales-c sales-d sales-e sales-f)
  ;set num-sales-list (list sales-a sales-b sales-c sales-d sales-e)
	; collections/num-sales list corresponds to initial num-sales as shown by dataset
  ask n-of 6 patches with [
  ;ask n-of 5 patches with [
    distancexy 0 0 = 20 and abs pxcor < (max-pxcor - 2) and
    abs pycor < (max-pycor - 2)
  ] [
    ; randomly placing collections around the center in the
    ; view with a fixed distance of 20 from the center - thus
    ; distance doesn't make a difference to their relative
    ; attractiveness
    sprout-collections 1 [
      set shape "hex"
      set size 2
      set color gray
      set discovered? false
    ]
  ]
  let i 0 ; assign num-tweets, num-sales and plot pens to each collection
  repeat count collections [
    ask collection i [
      set num-sales item i num-sales-list
      set label num-sales
      set num-tweets 0
      set num-tweets-period 0
      set num-tweets-hour 0
      ;set collection-timer 1200
      ;set visitors 0
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

to setup-people
  create-scouts 12000 [ ; JUSTIFY - approx 0.02% of twitter users are NFT early adopters ? (Sept 2021)
                        ; to give around 4 adopters to each collection, network must have 12,000 people minimum
    fd random-float 4 ; let people spread out from the center
    set my-home patch-here
    set shape "person"
    set color gray
    set initial-scout? false
    set target nobody
    set circle-switch 1
    set no-discovery? false
    set inspecting-collection? false
    set tweeting? false
    set watching-tweet? false
    set next-task watch-tweet-task
    set task-string "watching-tweet"
  ]
  ; assigning some of the scouts to be initial scouts.
  ; person-timer here determines how long they will wait
  ; before starting initial exploration
  set early-adopters (initial-percentage / 100) * (count scouts)
  ask n-of early-adopters scouts [
    set initial-scout? true
    set person-timer 5
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
    if initial-scout? and person-timer < 0 [
      ; a initial scout, after the waiting period,
      ; takes off to discover new collections.
      ; it has limited time to do the initial exploration,
      ; as specified by initial-explore-time.
      set next-task discover-task
      set task-string "discovering"
      set person-timer initial-explore-time
      set initial-scout? true
    ]
    if not initial-scout? [
      ; if a person is not a initial scout (either destined not to be
      ; or lost its initial scout status due to lack of
      ; purchase in its initial exploration), it watches other
      ; people in its cone of vision
      if person-timer < 0 [
        ; idle people have person-timer less than 0, usually as the
        ; result of reducing person-timer from executing other tasks,
        ; such as tweeting
        set watching-tweet? true
        if count other scouts in-cone 3 360 > 0 [
          let observed one-of scouts in-cone 3 360
          if [ next-task ] of observed = tweet-task [
            ; randomly pick one tweeting person in its cone of vision
            ; random x < 1 means a chance of 1 / x. in this case,
            ; x = ((1 / [interest] of observed) * 1000), which is
            ; a function to correlate interest, i.e. the enthusiasm
            ; of a tweet, with its probability of being followed:
            ; the higher the interest, the smaller 1 / interest,
            ; hence the smaller x, and larger 1 / x, which means
            ; a higher probability of being seen.
            ;if [interest] of observed = 0 [
              ;set interest 1 ; prevents division by zero in subsequent lines
            ;]
            if random ((influence / [interest] of observed) * 1000) < 1 [
              ; follow the tweet
              set target [target] of observed
              ; use white to a person's state of having in mind
              ; a target  without having visited it yet
              set color white
              set next-task re-visit-task
              ; re-visit could be an initial scout's subsequent
              ; repurchases of a collection after it discovered the collection,
              ; or it could be a non-initial scout's first purchase
              ; and subsequent purchases of a collection (because non-scouts
              ; don't make initial visit, which is defined as the
              ; discovering visit).
              set task-string "revisiting"
              set person-timer stagger
              set watching-tweet? false
            ]

          ]
        ]
      ]
    ]
    ; reduce people's waiting time by 1 tick
    set person-timer person-timer - 1
    ;set period-timer period-timer + 1
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;discover;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to discover
  set discover-task [ ->
    ifelse person-timer < 0 [
      ; if run out of time (a person has limited time to make initial
      ; discovery), go home, and admit no discovery was made
      set next-task go-home-task
      set task-string "going-home"
      set no-discovery? true
      set initial-scout? false
    ]
    [
      ; if a person finds collections around it (within a distance of 20) on its way
      ifelse count collections in-radius 20 > 0 [
        ; then randomly choose one to focus on
        let temp-target one-of collections in-radius 20
        ask temp-target [
          ;show xcor of turtle 0
          set occupation count scouts with [target = temp-target]
          ifelse occupation != 1[
          type temp-target type " is targeted by " type occupation print " people."
          ][
          type temp-target type " is targeted by " type occupation print " person."
          ]

        ]
        ; distributes early-adopters near-equally
        ifelse occupation < (early-adopters / 6) [
          ; commit to this collection
          set target temp-target
					let i 0
          ask target [
            ; make the target as discovered
            set discovered? true
            set color item who color-list
          ]
          ; collect info about the target
          set interest [ num-sales ] of target ; early adopters' interest in targets are based on their sales (i.e. performance on OpenSea)
          ; the person changes its color to show its commitment to this collection
          set color [ color ] of target
          set next-task inspect-collection-task
          set task-string "inspecting-collection"
          ; will inspect the target for 100 ticks
          set person-timer 100
          ;set collection-timer collection-timer - 1
        ]
        [
          ; if no collection collection is around, keep going forward
          ; with a random heading between [-60, 60] degrees
          rt (random 60 - random 60) proceed
          set person-timer person-timer - 1
          ;set period-timer period-timer + 1
        ]
      ] [
        rt (random 60 - random 60) proceed
      ]
      set person-timer person-timer - 1
      ;set period-timer period-timer + 1
    ]
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;inspect-collection;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to inspect-collection
  set inspect-collection-task [ ->
    ; after spending certain time (as specified in person-timer, see the
    ; last comment of this task) on inspecting collections, they visit home.
    ifelse person-timer < 0 [
      if not initial-scout? [
      ask target [
            set num-sales num-sales + 1
            ;show num-sales
            set label num-sales
       ]
      ]
      set next-task go-home-task
      set task-string "going-home"
      set inspecting-collection? false
      set initial-scout? false
      set trips trips + 1
    ] [
      ; while on inspect-collection task,
      if distance target > 2 [
        face target fd 1 ; a person visits its target collection
      ]
      set inspecting-collection? true
      let nearby-scouts scouts with [ inspecting-collection? and target = [ target ] of myself ] in-radius 3
      ; this line makes the visual effect of a person showing up and disappearing,
      ; representing the person checks both outside and inside of the collection
      ifelse random 3 = 0 [ hide-turtle ] [ show-turtle ]
      ; a person knows how far this collection is from its network
      set dist-to-collection distancexy 0 0
      ; the person-timer keeps track of how long the person has personn inspecting
      ; the collection. It lapses as the model ticks. it is set in either the
      ; discover task (100 ticks) or the re-visit task (50 ticks).
      set person-timer person-timer - 1
      ;set period-timer period-timer + 1
    ]
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;go-home;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to go-home
  set go-home-task [ ->
    ifelse distance my-home < 1 [ ; if back at home
      ifelse no-discovery? [
        ; if the person is an initial scout that failed to discover a collection collection
        set next-task watch-tweet-task
        set task-string "watching-tweet"
        set no-discovery? false
        ; it loses its initial scout status and becomes a
        ; non-scout, who watches other people's tweets
        set initial-scout? false
      ] [
          ; it prepares to tweet to advocate its target collection.
          ; it resets the person-timer to 0 for the tweet task
          set next-task tweet-task
          set task-string "tweeting"
          set person-timer 0
      ]
    ] [
      while [distance patch 0 0 > 1] [
      face patch 0 0 proceed
      ]
    ]
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;tweet;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; people tweet multiple rounds for a good collection. After exploring the collection for the first
; time, they return to the network and tweet enthusiastically about it for a lengthy period
; of time, and then go back to visit the collection again. When they return, they would tweet
; about it for another round, with slightly declined length and enthusiasm. such cycle repeats
; until the enthusiasm is completely gone. in the code below, interest represents
; a person's enthusiasm and the length of the tweeting period. trips keep track of how many times
; the person has visited the target. after each revisiting trip, the interest declines
; by 10%, as represented by (interest * 0.9).
; interest - (trips - 1) * (15 + random 5) determines how long a person will tweet after
; each trip. e.g. when a collection is first discovered (trips = 1), if the collection num-sales is
; 100, i.e. the person's initial interest in this collection is 100, it would tweet
; 100 - (1 - 1) * (15 + random 5) = 100. However, after 100 ticks of tweet, the person's
; interest in this collection would reduce to [85,81].
; Assuming it declined to 85, when the person tweets for the collection a second time, it
; would only tweet between 60 to 70 ticks: 85 - (2 - 1) * (15 + random 5) = [70, 66]
to tweet
  set tweet-task [ ->
    pen-up
    set heading random (360 - 0)
    fd random-float 3 ;distributes returning people throughout the network
      if person-timer > interest - (trips - 1) * (15 + random 5) and interest > 0 [
        ; if a person tweets longer than its current interest, and if it's still
        ; interested in the target, go to revisit the target again
        set next-task re-visit-task
        set task-string "revisiting"
        set tweeting? false
        pen-up
        set interest interest * 0.9 ; interest decline by 10%
        set person-timer 25                        ; revisit 25 ticks
      ]
      if person-timer > interest - (trips - 1) * (15 + random 5) and interest <= 0 [
        ; if a person tweets longer than its current interest, and if it's no longer
        ; interested in the target, as represented by interest <=0, stay in the
        ; network, rest for 50 ticks, and then watch tweet
        set next-task watch-tweet-task
        set task-string "watching-tweet"
        set tweeting? false
        set watching-tweet? true
        set target nobody
        set interest 0
        set trips 0
        set color gray
        set person-timer 50
      ]
      if person-timer <=  interest - (trips - 1) * (15 + random 5) [
        ; if a person tweets short than its current interest, keep tweeting
        ifelse interest <= 50 and random 100 < 43 [
          set next-task re-visit-task
          set task-string "revisiting"
          set tweeting? false
          set interest interest - (15 + random 5)
          set person-timer 10
        ] [
          set tweeting? true
          ask target[
          set num-tweets num-tweets + 1
          ifelse period-timer < period [
            set num-tweets-period num-tweets-period + 1
          ][
            set num-tweets-period num-tweets-hour
            set period-timer 0
            print "Period has lapsed. Timer reset"
          ]
          ifelse hourly-timer < (ticks-per-day / 24) [
            set num-tweets-hour num-tweets-hour + 1
          ][
            set num-tweets-hour 0
            set hourly-timer 0
            set hour-counter hour-counter + 1
            print hour-counter
            ;print "An hour has passed. Timer reset"
          ]

          if hour-counter > 23 [
            set hour-counter 0
            type "Day " type days print " has passed, with the following results:"
            let n 0
            repeat count collections [
              ask collection n [
                if n = 0 [type "Collection A:" print num-sales]
                if n = 1 [type "Collection B:" print num-sales]
                if n = 2 [type "Collection C:" print num-sales]
                if n = 3 [type "Collection D:" print num-sales]
                if n = 4 [type "Collection E:" print num-sales]
                if n = 5 [type "Collection F:" print num-sales]
              ]
              set n n + 1
            ]
            set days days + 1
          ]

        ]
          ifelse show-tweet-path? [pen-down][pen-up]
          repeat 2 [
            waggle
            make-semicircle]
        ]
      ]
      set person-timer person-timer + 1
      ;set period-timer period-timer + 1
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;re-visit;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to re-visit
  set re-visit-task [ ->
    ifelse person-timer > 0 [
      ; wait a bit after the previous trip
      set person-timer person-timer - 1
      ;set period-timer period-timer + 1
    ] [
      pen-up
      ifelse distance target < 1 [
        ; if on target, learn about the target
        if interest = 0 [
          set interest [ num-tweets-period ] of target ; members of the network's interest is secondary to that of early adopters
                                                       ; they operate on noise trading, thus their interest is based on the level
                                                       ; of 'noise' around a collection i.e. the number of tweets about it (within a
                                                       ; given time period JUSTIFY CHOSEN TP
          set color [ color ] of target
        ]
        set next-task inspect-collection-task
        set task-string "inspecting-collection"
        set person-timer 50
      ] [
        ; if hasn't reached target yet (distance > 1), keep visiting
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
  ;if all? scouts [ inspecting-collection? ] and length remove-duplicates [ target ] of scouts = 1 [
	(ifelse
    ticks < 14 * ticks-per-day [ ;two weeks worth of ticks
    	ask scouts [ run next-task ]
    	plot-inspecting-collection-scouts
      plot-tweet-sales
      tick
      set period-timer period-timer + 1
      set hourly-timer hourly-timer + 1
    ]
		[
    stop
  ])
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;utilities;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to make-semicircle
  ; calculate the size of the semicircle. 2600 and 5 (in pi / 5) are numbers
  ; selected by trial and error to make the tweet path look clear (Guo and Wilensky, 2014)
  if interest < 1 [
    set interest 1
  ] ; to make up for division by zero
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

  set circle-switch circle-switch * -1
  setxy temp-x-tweet temp-y-tweet
end

to waggle
  ; pointing the zigzag direction to the target
  face target
  set temp-x-tweet xcor set temp-y-tweet ycor
  ; switch toggles between 1 and -1, which makes a person tweet,
  ; as represented by a zigzag line going left and right
  let waggle-switch 1
  ; first part of a zigzag line
  lt 60
  fd .4
  ; correlates the number of turns in the zigzag line with the distance
  ; between the network and the collection. the number 2 is selected by trial
  ; and error to make the tweet path look clear (Guo and Wilensky, 2014)
  repeat (dist-to-collection - 2) / 2 [
    ; alternates left and right along the diameter line that points to the target
    if waggle-switch = 1 [rt 120 fd .8]
    if waggle-switch = -1 [lt 120 fd .8]
    set waggle-switch waggle-switch * -1
  ]
  ; finish the last part of the zigzag line
  ifelse waggle-switch = -1 [lt 120 fd .4][rt 120 fd .4]
end

to proceed
  rt (random 20 - random 20)
  if not can-move? 1 [ rt 180 ]
  fd 1
end

to move-around
  rt (random 60 - random 60) fd random-float .1
  if distancexy 0 0 > 4 [facexy 0 0 fd 1]
end

to plot-inspecting-collection-scouts
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
    plot count scouts with [target = collection i]

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
    ;set-current-plot "sales"
    ;set-current-plot-pen word "tweets" i
    ;plot count scouts with [target = collection 0]

    set i i + 1
  ]
end

to show-hide-tweet-path
  if show-tweet-path? [
    clear-drawing
  ]
  set show-tweet-path? not show-tweet-path?
end

to show-hide-scouts
  ifelse scouts-visible? [
    ask scouts [hide-turtle]
  ]
  [
    ask scouts [show-turtle]
  ]
  set scouts-visible? not scouts-visible?
end

; Copyright 2014 Uri Wilensky and 2022 Omotara Edu
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
210
10
933
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
1
1
1
ticks
120.0

BUTTON
5
235
201
271
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
5
275
200
315
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
145
201
178
initial-percentage
initial-percentage
0
5
0.2
0.1
1
%
HORIZONTAL

PLOT
942
222
1252
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
942
10
1252
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
5
320
200
356
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
5
365
200
405
Show/Hide Scouts
show-hide-scouts
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

INPUTBOX
5
10
60
70
sales-a
36.0
1
0
Number

INPUTBOX
70
10
130
70
sales-b
17.0
1
0
Number

INPUTBOX
145
10
195
70
sales-c
39.0
1
0
Number

INPUTBOX
5
75
60
135
sales-d
32.0
1
0
Number

INPUTBOX
70
80
125
140
sales-e
214.0
1
0
Number

INPUTBOX
140
80
200
140
sales-f
19.0
1
0
Number

SLIDER
15
185
187
218
influence
influence
0
100
50.0
1
1
%
HORIZONTAL

PLOT
940
430
1330
765
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
