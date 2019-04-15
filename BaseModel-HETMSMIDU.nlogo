;; THIS IS MAIN FILE. MOST procedure called from here
__includes
[
  "Data.nls" "testing-frequency.nls" "manage-age-group.nls" "manage-care-continuum.nls" "set-dropout-care.nls"
  "initial-people.nls" "initialize-transmissions.nls" "global-initialization.nls" "breed-people.nls" "update-simulation.nls"
  "manage-partnership.nls" "generate-transmission.nls" "verify-plot.nls" "write-output.nls" "FiniteQLearningUpdate.nls" "OptimalPolicyUpdate.nls"
]

extensions [matrix csv profiler table]
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; Initial SETUP
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; check runtime of each procedure
to profile

  profiler:start; start profiling
  repeat 1 [runExperiment]; excute procedure runExperiment to measure run time
  profiler:stop; stop profiling
  print profiler:report; view the results
  profiler:reset; clear the data

end

;; Initially settiing up x number of people
to setup

  ;; (for this model to work with NetLogo's new plotting features,
  ;; __clear-all-and-reset-ticks should be replaced with clear-all at
  ;; the beginning of your setup procedure and reset-ticks at the end
  ;; of the procedure.)

  clear-ticks
  clear-turtles
  clear-patches
  clear-drawing
  clear-all-plots ;__clear-all-and-reset-ticks  ;;clear all

  setup-intermediate-globals
  setup-static-globals

  set prevalence replace-item 0 prevalence (number-people * item 0 sex-dist-target / num-HET-FEM)
  set prevalence replace-item 1 prevalence (number-people * item 1 sex-dist-target / num-HET-MEN)
  set prevalence replace-item 2 prevalence (number-people * item 2 sex-dist-target / num-MSM)
  set prevalence replace-item 3 prevalence (number-people * item 3 sex-dist-target / num-IDU-FEM)
  set prevalence replace-item 4 prevalence (number-people * item 4 sex-dist-target / num-IDU-MEN)
  set prevalence replace-item 5 prevalence (number-people * item 5 sex-dist-target / num-IDU-MSM)

;  print(word"initial num-het-fem:" num-het-fem)
;  print(word"setup num-het-men:" num-het-men)
;  print(word"setup num-het-msm:" num-msm)
;  print(word"setup num-IDU-fem:" num-IDU-fem)
;  print(word"setup num-IDU-men:" num-IDU-men)
;  print(word"setup num-IDU-msm:" num-IDU-msm)
;  print(word"setup total population:" (num-het-fem + num-het-men + num-msm + num-IDU-fem + num-IDU-men + num-IDU-msm))
;  print(word"setup infected:" count people with [infected? = true and dead = 0 and sex >= 1 and stage >= 1])
;  print(word"setup:" prevalence)


  setup-initial-people ;;function in 'initialize-people-HET-MSM.nls': matches the initial population to represent 2006 HIV

  ;check-setup ;; see next procedure below: used for verification
  setup-people ;; procedure below
               ;; next few setup are some of the plots.
               ;;However most of the results analysis has been conducted in excel files. (See ReadMe.doc in the folder)
  ;setup-plot
  ;setplot-het-stage
  ;setplot-MSM-stage
  ;setplot-CD4-diagnosis-HET
  ;setplot-CD4-diagnosis-MSM
  ;setplot-PLWH

end

;; Generating a number of dummy people who just stay in the simulation, just as a reserve of people to infect.
;; When a new infection occurs later in the simulation, a dummy person is set as HIV-positive
to setup-people

  create-people number-people * 0.3
  [
    set index? false ;; the initial population are called
    set infected? false
  ]

end

;; Repeat simulation for x times
to runExperiment

  initialize-output
  ;setup-sensitive-global-var
  ;initialize-sensitive-globals
  ;assign-sensitive-globals


  if goal = 1
  [
    carefully [file-delete "results-ptnr-one.csv"] []
    carefully [file-delete "results-PLWH-one.csv"] []
    carefully [file-delete "results-new-infections-one.csv"] []
  ]
  if goal = 2
  [
    carefully [file-delete "results-ptnr-two.csv"] []
    carefully [file-delete "results-PLWH-two.csv"] []
    carefully [file-delete "results-new-infections-two.csv"] []
  ]
  if goal = 3
  [
    carefully [file-delete "results-ptnr-three.csv"] []
    carefully [file-delete "results-PLWH-three.csv"] []
    carefully [file-delete "results-new-infections-three.csv"] []
  ]
  if goal = 4
  [
    carefully [file-delete "results-ptnr-four.csv"] []
    carefully [file-delete "results-PLWH-four.csv"] []
    carefully [file-delete "results-new-infections-four.csv"] []
  ]
  if goal = 5
  [
    carefully [file-delete "results-ptnr-five.csv"] []
    carefully [file-delete "results-PLWH-five.csv"] []
    carefully [file-delete "results-new-infections-five.csv"] []
  ]

  carefully [file-delete "results-cohort-info.csv"] []

;  write-cohort-header

  set tempRun 0
  while [tempRun < maxRun]
  [
    setup
    ;check-globals
    reset-ticks
    repeat maxTicks [go]
    set tempRun tempRun + 1
    print (word "Completed run #:" tempRun)
  ]

;  write-PLWH-header
;  write-results-PLWH
;  write-new-infections-header
;  write-results-new-infections
;  write-ptnr-header
;  write-results-ptnr

end

;; Below procedure is repeated every time unit
to go

  ;; The first 100 ticks (each tick is a month)
  if ticks < sim-dry-run
  [
    first-100-ticks
    tick
  ]

  ;; Tick 101
  if ticks = sim-dry-run
  [
    tick-101
    tick
  ]

  ;; discounting to year 2006, change proportions in care cascade components from 2012 to 2015
  ;; first dry-run years keeping at 2006 levels as a dry run

  if ticks > sim-dry-run
  [
    ;; calculate the number of PLWH by sex/risk group

    if ticks = sim-dry-run + 1
    [
      set total-people people with [dead = 0 and infected? = true]
      let i 0
      repeat num-sex
      [
        set total-people-sex replace-item i total-people-sex total-people with [sex = i + 1]
        set i i + 1
      ]
    ]

    ;; first 15 years dry-run, keep prevalence the same as 2006
    dry-run-keep-prevalence
    set ptnrs-per-month n-values 8 [0]

    ;; change needle transmission rates after dry run
    if ticks = t-start + 1
    [set trans-rate-needle trans-rate-needle-after-dry-run]
;    if (ticks - sim-dry-run) mod time-unit = 0 and ticks > t-start and ticks < tick-start
;    [set trans-rate-needle trans-rate-needle * percent-sharing-decline]

    ;; change the CD4 guideline to start ART treatment throughout the years
    if ticks = t-start + time-unit * 3 + 1
    [set CD4-start-ART-guideline CD4-start-ART-guideline2]
    if ticks = t-start + time-unit * 6 + 1
    [set CD4-start-ART-guideline CD4-start-ART-guideline3]

    ;; tracking HIV prevalence in each sex/risk group

    if ticks = t-start
    [
;                 print(word"2006 num-het-fem:" num-het-fem)
;  print(word"2006 num-het-men:" num-het-men)
;  print(word"2006 num-het-msm:" num-msm)
;  print(word"2006 num-IDU-fem:" num-IDU-fem)
;  print(word"2006 num-IDU-men:" num-IDU-men)
;  print(word"2006 num-IDU-msm:" num-IDU-msm)
;  print(word"2006 total population:" (num-het-fem + num-het-men + num-msm + num-IDU-fem + num-IDU-men + num-IDU-msm))
;  print(word"2006 infected:" count people with [infected? = true and dead = 0 and sex >= 1 and stage >= 1])
;  print(word"2006:" prevalence)
    ]
    if ticks >= t-start + 1
    [
      count-num-HIV
      ;count-num-sharing-HIV

    ]

    ;; change sexual behavior based on age (procedures in manage-partnership.nls)
    ask total-people with [age mod 1 = 0]
    [
      set-num-ptnr
      set-sexual-behavior
    ]

    ;; managing proportion of individuals with concurrent ptnrs (procedure in manage-partnership.nls)
    let i 0
    repeat num-sex
    [
      manage-concurrency i
      set i i + 1
    ]

    ;; procedure in update-simulation.nls. This is the disease progression model (PATH 1.0)
    ask total-people
    [
      ;; monthly parameters to track infections
      set num-trans-One 0
      set num-trans-Two 0
      set num-trans-Casual 0
      set num-trans-Needle 0
      ;; disease progression within each PLWH
      update-simulation
    ]

    ;; Before 2015
    ;; "Bucket approach" to match proportion of PLWH along each stage of the HIV care continuum
    ;; 1) people when diagnosed are assigned probability they link to care within a month to 3;
    ;; 2) people who drop-out of care are asigned when they come back to care based on CD4 count.

;    if ticks = tick-start
;    [
;      ask people with [dead = 0 and infected? = true and stage <= 2 and trans-year <= dry-run + calibration-year - start-year]
;      [set next-test ticks + 1 + random (test-freq-pre2015 - 1)]
;    ]
;
    set i 0
    ;ifelse ticks <= tick-start
    ;[
      repeat num-sex
      [
      manage-undiag i
      manage-no-care i
      manage-care-noART i
      if ticks <= maxTicks
        [manage-not-VLS-dropOut i]
      manage-VLS-dropOut i
        set i i + 1
      ]
;    ]
;    [
;      manage-linkToCare
;      manage-ART-post2015
;      manage-dropOut-post2015
;    ]

    ;; accumulating person-years for each continuum stages, each age group, and each sex/risk group
    accum-person-years

    ;;for individuals in acute phase infection cutting down to weekly time unit and estimating transmissions every week
    acute-infection

    ;; for individuals not in acute phase estimating tarnsmissions every month
    non-acute-infection

    ;; controlling for distribution of age at infection
    if (ticks - sim-dry-run) mod time-unit = 0
    [
      ifelse ticks <= t-start
      [set PLWH 1]
      [set PLWH 2]
      manage-age-group
    ]

    ;; As trasnmissions occurred the dummy people from reserve (who were infected and in no way part of simulation)
    ;; were taken and set as infected to denote the infected person. Here creating more people in reserve.
    if (count people with [infected? = false]) <= 3 * number-people * 1 / 12
    [setup-people]

    ;; generating output every year. Since each tick is assumed a month we write outputs only every year
    ;; generarte transmissions for num-year-trans years
    if (ticks - sim-dry-run) mod time-unit = 0 and ticks <= (sim-dry-run + time-unit * num-year-trans)
    [
      if ticks >= t-start
      [
        let year (ticks - t-start) / time-unit
        ;; all PLWH
        set total-people people with [infected? = true and dead = 0]
        set total-pop count total-people
        set i 0
        repeat num-stage
        [
          set total-people-stage replace-item i total-people-stage total-people with [stage = i + 1]
          set i i + 1
        ]
        set i 0
        repeat num-sex
        [
          set total-people-sex replace-item i total-people-sex total-people with [sex = i + 1]
          set i i + 1
        ]
        set i 0
        repeat num-age
        [
          set total-people-age replace-item i total-people-age total-people with [age >= item i age-LB and age < item i age-UB]
          set i i + 1
        ]
        ;generate-PLWH year
        ;; all new infections
        set newly-infected total-people with [trans-year = ceiling ((ticks - sim-dry-run) / time-unit)]
        set newly-dead people with [dead-year = ceiling ((ticks - sim-dry-run) / time-unit)]
        set i 0
        repeat num-sex
        [
          set newly-infected-sex replace-item i newly-infected-sex newly-infected with [sex = i + 1]
          set i i + 1
        ]
        set i 0
        repeat num-age
        [
          set newly-infected-age replace-item i newly-infected-age newly-infected with [age < item i age-UB and age >= item i age-LB]
          set i i + 1
        ]
        ;generate-new-infections year
        ;generate-ptnrs year
      ]

      set count-trans-by-stage n-values num-stage [0] ;; resetting counters every year
      set count-trans-by-sex n-values num-sex [0]
      set count-trans-by-age n-values num-age [0]

      set count-trans-by-ptnr-type [0 0 0 0 0 0 0];;;; resetting counters year

      set count-person-years-by-stage n-values num-stage [0]
      set count-person-years-by-age n-values num-age [0]
      set count-person-years-by-sex n-values num-sex [0]

      set numACTStable3 [0 0 0 0 0 0]; resetting counters year
      set numTranstable3 [0 0 0 0 0 0];  resetting counters year
      set countNewDiagnosis [0 0 0 0 0 0];  resetting counters new diagnosis

      ask people with [infected? = true]
      [
        set counter-ptnr replace-item 0 counter-ptnr (item 0 ptnr-array)
        set counter-ptnr replace-item 1 counter-ptnr (item 1 ptnr-array)
        set counter-ptnr replace-item 2 counter-ptnr 0
        set counter-ptnr replace-item 3 counter-ptnr 0
      ]
    ]
    tick
  ]

;  if ticks <= tick-start + 1 and ticks >= tick-start - time-unit + 1
;  [set cohort people with [infected? = true and trans-year = dry-run + calibration-year - start-year + 1]]
;
;  if ticks <= tick-start + 60 * time-unit and ticks >= tick-start - time-unit + 1
;  [
;    set life-years life-years + count cohort with [dead = 0] / time-unit
;    set QALY-accumulate QALY-accumulate + sum [QALYs] of cohort / time-unit
;  ]
;
;  let i 0
;  while [i < 20]
;  [
;    if ticks <= tick-start + i * time-unit and ticks >= tick-start + (i - 1) * time-unit + 1
;    [
;      set VLS-accumulate replace-item i VLS-accumulate (item i VLS-accumulate + ((count cohort with [stage = 6 and dead = 0]) / time-unit))
;      set all-accumulate replace-item i all-accumulate (item i all-accumulate + ((count cohort with [dead = 0]) / time-unit))
;    ]
;    set i i + 1
;  ]

  if ticks > (sim-dry-run + time-unit * num-year-trans) + 1
  [
;    set i 0
;    while [i < 20]
;    [
;      if item i all-accumulate > 0
;      [
;        set avg-VLS replace-item i avg-VLS (item i VLS-accumulate / item i all-accumulate)
;        set avg-num-trans replace-item i avg-num-trans (item i num-cohort-trans / item i all-accumulate)
;      ]
;      set i i + 1
;    ]
;    write-cohort-info
    stop
  ]

end

;;updates prevalence every year;;
to count-num-HIV
   set total-people people with [dead = 0 and infected? = true]
;  set prevalence replace-item 0 prevalence (count total-people with [sex = 1] / num-HET-FEM)
;  set prevalence replace-item 1 prevalence (count total-people with [sex = 2] / num-HET-MEN)

  ;;update population.
  set num-HET-FEM num-HET-FEM + (births-HET-FEM / time-unit) - (count people with [sex = 1 and dead = 1] - prevDeaths-HET-FEM)
  set num-HET-MEN num-HET-MEN + (births-HET-MEN / time-unit) - (count people with [sex = 2 and dead = 1] - prevDeaths-HET-MEN)
  set num-MSM num-MSM + (births-MSM / time-unit) - (count people with [sex = 3 and dead = 1] - prevDeaths-MSM)
  set num-IDU-FEM num-IDU-FEM + (births-IDU-FEM / time-unit) - (count people with [sex = 4 and dead = 1] - prevDeaths-IDU-FEM)
  set num-IDU-MEN num-IDU-MEN + (births-IDU-MEN / time-unit) - (count people with [sex = 5 and dead = 1] - prevDeaths-IDU-MEN)
  set num-IDU-MSM num-IDU-MSM + (births-IDU-MSM / time-unit) - (count people with [sex = 6 and dead = 1] - prevDeaths-IDU-MSM)

  set prevDeaths-HET-FEM count people with [sex = 1 and dead = 1]
  set prevDeaths-HET-MEN count people with [sex = 2 and dead = 1]
  set prevDeaths-MSM count people with [sex = 3 and dead = 1]
  set prevDeaths-IDU-FEM count people with [sex = 4 and dead = 1]
  set prevDeaths-IDU-MEN count people with [sex = 5 and dead = 1]
  set prevDeaths-IDU-MSM count people with [sex = 6 and dead = 1]


  set prevalence replace-item 0 prevalence (count item 0 total-people-sex / num-HET-FEM)
  set prevalence replace-item 1 prevalence (count item 1 total-people-sex / num-HET-MEN)
  set prevalence replace-item 2 prevalence (count item 2 total-people-sex / num-MSM)
  set prevalence replace-item 3 prevalence (count item 3 total-people-sex / num-IDU-FEM)
  set prevalence replace-item 4 prevalence (count item 4 total-people-sex / num-IDU-MEN)
  set prevalence replace-item 5 prevalence (count item 5 total-people-sex / num-IDU-MSM)



end

to count-num-sharing-HIV

  set total-sharing people with [dead = 0 and infected? = true and needle-sharing? = true]
  if percent-IDU-sharing > 0
  [
    set sharing-prevalence replace-item 3 sharing-prevalence (count total-sharing with [sex = 4] / (num-IDU-FEM * percent-IDU-sharing))
    set sharing-prevalence replace-item 4 sharing-prevalence (count total-sharing with [sex = 5] / (num-IDU-MEN * percent-IDU-sharing))
    set sharing-prevalence replace-item 5 sharing-prevalence (count total-sharing with [sex = 6] / (num-IDU-MSM * percent-IDU-sharing))
    set IDU-sharing-prevalence (count total-sharing with [sex >= 4] / ((num-IDU-FEM + num-IDU-MEN + num-IDU-MSM) * percent-IDU-sharing))
  ]

end

to update-stage-props [i]

  set current-unaware matrix:get-row matrix_unaware i
  set current-no-care matrix:get-row matrix_noCare i
  set current-care-noART matrix:get-row matrix_careNoART i
  set current-ARTsuppressed matrix:get-row matrix_ARTVLS i
  set care-at-diag matrix:get-row matrix_LinkageToCare i
  ;set care-at-diag-ByAge matrix:get-row matrix_LinkageToCare_ByAge i

end

;; first 100 ticks, dry run
to first-100-ticks

  ;;updates prevalence of HIV among the different populations
  ask initial-people with [infected? = true]
  [
    set num-trans-One 0; count of transmission to main ptnr
    set num-trans-Two 0; count of transmission to concurrent ptnr
    set num-trans-Casual 0; count of transmission to casual ptnr
    set num-trans-Needle 0; count of transmission to needle sharing ptnr if IDU
    setup-trans-non-acute
  ]

end

;; update at 101st tick
to tick-101

  ;; set prevalence of HIV using number infected divided by total population in US
  ;; prevalence is updated as we project new infections for future years
  ask initial-people with [infected? = true]
  [
    set num-trans-One 0
    set num-trans-Two 0
    set num-trans-Casual 0
    set num-trans-Needle 0

    ;; will convert breed "initial-people-HET-MSM" to breed "people".
    ;; changing breed just so it is easier to model, will also assign test and care status to match 2006 population
    ;; procedure in initial-people.nls
    set-HIV-variables
    set index? true

    ;; procedure in  "testing-frequency.nls"
    ifelse stage < 3
    [set-next-test]
    [set next-test 0]

    ;; resetting counter for ptnrs
    set counter-ptnr replace-item 0 counter-ptnr (item 0 ptnr-array)
    set counter-ptnr replace-item 1 counter-ptnr (item 1 ptnr-array)
    set counter-ptnr replace-item 2 counter-ptnr 0
    set counter-ptnr replace-item 3 counter-ptnr 0
  ]

end

to dry-run-keep-prevalence

  ifelse ticks <= t-start;; dry run for 15 years, since new people get infected every year prevalence changes but since 15 yeras is dry run we want to maintain 2006 prevalence
  [
    set num-HET-FEM count item 0 total-people-sex / item 0 prevalence
    set num-HET-MEN count item 1 total-people-sex / item 1 prevalence
    set num-MSM count item 2 total-people-sex / item 2 prevalence
    set num-IDU-FEM count item 3 total-people-sex / item 3 prevalence
    set num-IDU-MEN count item 4 total-people-sex / item 4 prevalence
    set num-IDU-MSM count item 5 total-people-sex / item 5 prevalence
    ;; for 2012 prevalence per 100,000 is 573;; for 2008 it is 470;; 2006 is 441
  ]
  [update-stage-props (floor((ticks - t-start - 1) / time-unit))]

end

to acute-infection

  ;; individuals in acute phase are recently infected ones
  ask total-people with [(age - age-at-infection) <= 3 / 12 and stage < 2] ;; first 3 months of infection
  [
    ;; keep track of those infected between 2011 and 2015 if set at between years 19 and 25 (name is misleading)
    if ticks > sim-dry-run + time-unit * 19 and ticks <= sim-dry-run + time-unit * 24
    [set infected-2013-2022? true]

    ;; determine months since infection. Used to model acute phase transmissions which varies weekly
    let start-week 1
    ifelse age - age-at-infection <= 1 / 12 ;; first month of infections
    [set start-week 1]
    [
      ifelse age - age-at-infection <= 2 / 12 ;; 2nd month of infection
      [set start-week 5]
      [set start-week 9] ;; third month of infection
    ]

    set count-casuals item 2 counter-ptnr

    ;; counters to track num acts during month when in acute phase
    set casuals-monthly-counter 0
    set acts-monthly-counter 0

    if item 0 ptnr-infected? = false
    [set monthly-ptnr1 false]

    if item 1 ptnr-infected? = false
    [set monthly-ptnr2 false]

    let i 0
    while [i < 4]
    [
      ;; determine transmission in non-acute phase
      ;; number of transmissions across all weeks are added up in setup-trans-acute
      setup-trans-acute start-week + i
      set i i + 1
    ]

    ;; count number of transmissions stratified by sex, age, and care continuum
    count-transmission
  ]

end

to non-acute-infection

  ask total-people with [(age - age-at-infection) > 3 / 12 or stage >= 2]
  [
    set count-casuals item 2 counter-ptnr

    ;; determine transmission in non-acute phase
    setup-trans-non-acute

    ;; count number of transmissions stratified by sex, age, and care continuum
    count-transmission
  ]

end

to count-transmission

  ;; track number of ptnrs per month for casual sexual
  if sex >= 4
  [
    let inter-val (item 0 ptnr-array + item 1 ptnr-array + (item 2 counter-ptnr - count-casuals))
    set ptnrs-per-month replace-item inter-val ptnrs-per-month (item inter-val ptnrs-per-month + 1)
  ]

  ;; accumulate transmissions
  set number-transmissions num-trans-One + num-trans-Two + num-trans-Casual + num-trans-Needle
  set life-time-transmissions life-time-transmissions + number-transmissions

  let val item (stage - 1) count-trans-by-stage + number-transmissions
  set count-trans-by-stage replace-item (stage - 1) count-trans-by-stage val

  set val item (sex - 1) count-trans-by-sex + number-transmissions
  set count-trans-by-sex replace-item (sex - 1) count-trans-by-sex val

  let i 0
  while [i < num-age]
  [
    ifelse age < item i age-UB
    [
      set val item i count-trans-by-age + number-transmissions
      set count-trans-by-age replace-item i count-trans-by-age val
      set i num-age
    ]
    [set i i + 1]
  ]

  ;; count transmissions by ptnr type: 0= HET main to main(het has only main); 6 = HET main (main or concurrent)
  ;; 1= MSM bisexula to female; 2 = MSM bisexual to MSM
  ; count-by-ptnr-type

  ;; calculate number of transmission by transmission type
  ;table3

  ;; a dummy variable used in redistributing age
  set dummy 0

end

to accum-person-years

  ;; person years by stage

  set total-people people with [infected? = true and dead = 0]

  let i 0
  repeat num-stage
  [
    set total-people-stage replace-item i total-people-stage total-people with [stage = i + 1]
    set count-person-years-by-stage replace-item i count-person-years-by-stage
        (item i count-person-years-by-stage + count (item i total-people-stage) / time-unit)
    set i i + 1
  ]

  ;; person years by age
  set i 0
  repeat num-age
  [
    set total-people-age replace-item i total-people-age total-people with [age >= item i age-LB and age < item i age-UB]
    set count-person-years-by-age replace-item i count-person-years-by-age
        (item i count-person-years-by-age + count (item i total-people-age) / time-unit)
    set i i + 1
  ]

  ;; person years by sex/risk group
  set i 0
  repeat num-sex
  [
    set total-people-sex replace-item i total-people-sex total-people with [sex = i + 1]
    set count-person-years-by-sex replace-item i count-person-years-by-sex
        (item i count-person-years-by-sex + count (item i total-people-sex) / time-unit)
    set i i + 1
  ]

end

to count-by-ptnr-type

  let val 0

  ifelse sex <= 2 or sex = 4 or sex = 5
  [ifelse (item 0 ptnr-array = 1) and (item 0 ptnr-array + item 1 ptnr-array + (item 2 counter-ptnr  - count-casuals)) = 1
    [set val num-trans-One + item 0 count-trans-by-ptnr-type
      set count-trans-by-ptnr-type replace-item 0 count-trans-by-ptnr-type val]
    [set val num-trans-One + num-trans-Two + num-trans-Casual + item 6 count-trans-by-ptnr-type
      set count-trans-by-ptnr-type replace-item 6 count-trans-by-ptnr-type val]
  ]
  [if (sex = 3 or sex = 6) and bi-sexual? = true and mix? = true
    [set val num-trans-One + num-trans-Two + num-trans-Casual + item 1 count-trans-by-ptnr-type
      set count-trans-by-ptnr-type replace-item 1 count-trans-by-ptnr-type val]

    if (sex = 3 or sex = 6) and bi-sexual? = true and mix? = false
    [set val num-trans-One + num-trans-Two + num-trans-Casual + item 2 count-trans-by-ptnr-type
      set count-trans-by-ptnr-type replace-item 2 count-trans-by-ptnr-type val]

        ;; count transmissions by ptnr type: 3= MSM to  MSM (MSM has only 1 main);
        ;4= MSM to MSM (MSM has 1 or 2 main may or maynot have casuals); 5= MSM to casual ptnrs ;
    if (sex = 3 or sex = 6)
    [if (item 0 ptnr-array = 1) and (item 0 ptnr-array + item 1 ptnr-array + (item 2 counter-ptnr  - count-casuals)) = 1
      [set val num-trans-One + num-trans-Two + item 3 count-trans-by-ptnr-type
        set count-trans-by-ptnr-type replace-item 3 count-trans-by-ptnr-type val]

      if (item 0 ptnr-array = 1) or (item 1 ptnr-array = 1 )
        [set val num-trans-One + num-trans-Two +  item 4 count-trans-by-ptnr-type
          set count-trans-by-ptnr-type replace-item 4 count-trans-by-ptnr-type val]

      set val num-trans-Casual + item 5 count-trans-by-ptnr-type
      set count-trans-by-ptnr-type replace-item 5 count-trans-by-ptnr-type val
    ]
  ]

end

to table3

  let val 0

  ifelse (age - age-at-infection) <= 0.09
  [if (sex = 3 or sex = 6) and (item 0 ptnr-array + item 1 ptnr-array + (item 2 counter-ptnr  - count-casuals)) > 1
    [set val num-trans-One + num-trans-Two + num-trans-Casual + item 0 numTranstable3
      set numTranstable3 replace-item 0 numTranstable3 val]
  ]
  [;2.
    if (sex = 3 or sex = 6) and item 0 ptnr-array = 1 and (item 0 ptnr-array + item 1 ptnr-array + (item 2 counter-ptnr - count-casuals)) = 1
    [set val num-trans-One + item 1 numTranstable3
      set numTranstable3 replace-item 1 numTranstable3 val]
    ;3.
    if (sex = 3 or sex = 6) and (item 2 counter-ptnr - count-casuals) = 1 and (item 0 ptnr-array + item 1 ptnr-array + (item 2 counter-ptnr  - count-casuals)) = 1
    [set val num-trans-Casual + item 2 numTranstable3
      set numTranstable3 replace-item 2 numTranstable3 val]
    ;4.
    if (sex = 3 or sex = 6) and (item 0 ptnr-array + item 1 ptnr-array) = 2 and (item 2 counter-ptnr  - count-casuals) = 0
    [set val num-trans-One + num-trans-Two + item 3 numTranstable3
      set numTranstable3 replace-item 3 numTranstable3 val]
    ;5.
    if (sex = 3 or sex = 6) and (item 2 counter-ptnr - count-casuals) > 1 and (item 0 ptnr-array + item 1 ptnr-array) = 0
    [set val num-trans-Casual + item 4 numTranstable3
      set numTranstable3 replace-item 4 numTranstable3 val]
    ;6.
    if (sex = 3 or sex = 6) and (item 2 counter-ptnr  - count-casuals) > 0 and (item 0 ptnr-array + item 1 ptnr-array) > 0
    [set val num-trans-One + num-trans-Two + num-trans-Casual + item 5 numTranstable3
      set numTranstable3 replace-item 5 numTranstable3 val]
  ]

end

;to calibrate
;
;  set caliMax 100
;  set caliRun 0
;  let sex-ind 0
;  let temp-pos 0
;  let temp-neg 0
;  let dist-gap n-values num-sex [0]
;  let step-size 0
;  let sex-dist-absolute-error n-values num-sex [0]
;  let sex-dist-percentage-error n-values num-sex [0]
;  while [caliRun < caliMax]
;  [runExperiment
;    ;print sex-dist-after
;    ;print sex-dist-before
;    ;print ratio
;    set sex-ind 0
;    set temp-pos 0
;    set temp-neg 0
;    while [sex-ind < num-sex]
;    [set dist-gap replace-item sex-ind dist-gap (item sex-ind sex-dist-target - item sex-ind sex-dist-after)
;      ifelse item sex-ind dist-gap > 0
;      [set temp-pos temp-pos + item sex-ind dist-gap]
;      [if item sex-ind dist-gap < 0
;        [set temp-neg temp-neg + abs(item sex-ind dist-gap)]
;      ]
;      set sex-ind sex-ind + 1
;    ]
;
;    set step-size min(list temp-pos temp-neg) / 2
;
;    set sex-ind 0
;    set sex-dist-absolute-error n-values num-sex [0]
;    set sex-dist-percentage-error n-values num-sex [0]
;    while [sex-ind < num-sex]
;    [set sex-dist-absolute-error replace-item sex-ind sex-dist-absolute-error (precision (100 * abs(item sex-ind sex-dist-target - item sex-ind sex-dist-after)) 2)
;      set sex-dist-percentage-error replace-item sex-ind sex-dist-percentage-error (precision (100 * abs(item sex-ind sex-dist-target - item sex-ind sex-dist-after) / item sex-ind sex-dist-target) 2)
;      set sex-ind sex-ind + 1]
;
;    print (word "Calibration run #:" (caliRun + 1))
;    print (word "Absolute error :" sex-dist-absolute-error)
;    print (word "Mean absolute error :" precision (mean sex-dist-absolute-error) 1)
;    print (word "Std absolute error :" precision (standard-deviation sex-dist-absolute-error) 1)
;    print (word "Percentage error :" sex-dist-percentage-error)
;    print (word "Mean percentage error :" precision (mean sex-dist-percentage-error) 1)
;    print (word "Std percentage error :" precision (standard-deviation sex-dist-percentage-error) 1)
;    print (word "Before dry-run distribution :" sex-dist-before)
;    print (word "After dry-run distribution :" sex-dist-after)
;    print (word "Targeted distribution after dry run :" sex-dist-target)
;    print (word "Distributuion gap :" dist-gap)
;
;    set sex-ind 0
;    while [sex-ind < num-sex]
;    [ifelse item sex-ind dist-gap > 0
;      [set sex-dist-before replace-item sex-ind sex-dist-before ((item sex-ind sex-dist-before) + step-size * (item sex-ind dist-gap) / temp-pos)]
;      [if item sex-ind dist-gap < 0
;        [set sex-dist-before replace-item sex-ind sex-dist-before ((item sex-ind sex-dist-before) + step-size * (item sex-ind dist-gap) / temp-neg)]
;      ]
;      set sex-ind sex-ind + 1
;    ]
;
;    set caliRun caliRun + 1
;  ]
;
;end
@#$#@#$#@
GRAPHICS-WINDOW
741
230
954
384
-1
-1
5.0
1
10
1
1
1
0
1
1
1
-20
20
-14
14
1
1
1
ticks
30.0

PLOT
111
281
428
401
CD4 count at diagnosis - Heterosexuals
NIL
NIL
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"<=200" 1.0 0 -16777216 true "" ""
"200-350" 1.0 0 -13345367 true "" ""
"350-500" 1.0 0 -5825686 true "" ""
">500" 1.0 0 -10899396 true "" ""

INPUTBOX
938
244
1025
304
number-people
1000.0
1
0
Number

BUTTON
935
409
998
442
setup
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

PLOT
440
10
781
135
People living with HIV/AIDS
Years
Number
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"MSM" 1.0 0 -13791810 true "" ""
"Heterosexual-female" 1.0 0 -13345367 true "" ""
"ALL" 1.0 0 -16777216 true "" ""
"Heterosexual-male" 1.0 0 -10899396 true "" ""

BUTTON
1008
411
1071
444
go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

INPUTBOX
866
328
954
388
simulation-years
0.0
1
0
Number

INPUTBOX
937
184
987
244
time-unit
12.0
1
0
Number

PLOT
10
10
450
268
Transmissions
NIL
NIL
0.0
0.0
0.0
0.0
true
true
"" ""
PENS
"ALL" 1.0 0 -16777216 true "" ""
"HET-female" 1.0 0 -13345367 true "" ""
"MSM" 1.0 0 -13791810 true "" ""
"Trans per 10000 PLWH" 1.0 0 -5825686 true "" ""
"HET-male" 1.0 0 -10899396 true "" ""

PLOT
-5
298
245
433
Stage Distribution- Heterosexuals
NIL
NIL
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"acute-unaware" 1.0 0 -16777216 true "" ""
"non-acute-unaware" 1.0 0 -7500403 true "" ""
"aware-no care" 1.0 0 -2674135 true "" ""
"aware-care-no ART" 1.0 0 -955883 true "" ""
"ART-not suppressed" 1.0 0 -1184463 true "" ""
"ART-suppressed" 1.0 0 -10899396 true "" ""

PLOT
482
161
761
326
Stage Distribution- MSM
NIL
NIL
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"acute-unaware" 1.0 0 -16777216 true "" ""
"non-acute-unaware" 1.0 0 -7500403 true "" ""
"aware-no care" 1.0 0 -2674135 true "" ""
"aware-care-no ART" 1.0 0 -955883 true "" ""
"ART-not suppressed" 1.0 0 -1184463 true "" ""
"ART-suppressed" 1.0 0 -10899396 true "" ""

PLOT
482
368
750
488
CD4 count at diagnosis - MSM
NIL
NIL
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"<=200" 1.0 0 -16777216 true "" ""
"200-350" 1.0 0 -13345367 true "" ""
"350-500" 1.0 0 -5825686 true "" ""
">500" 1.0 0 -10899396 true "" ""

PLOT
116
405
484
555
Proportion transmissions in stage
NIL
NIL
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"acute-unaware" 1.0 0 -16777216 true "" ""
"non-acute-unaware" 1.0 0 -7500403 true "" ""
"aware-no care" 1.0 0 -2674135 true "" ""
"aware-care-no ART" 1.0 0 -955883 true "" ""
"ART-not suppressed" 1.0 0 -1184463 true "" ""
"ART-suppressed" 1.0 0 -10899396 true "" ""

MONITOR
1042
347
1099
392
undiag
count people with [stage = 2 and dead = 0 and index? = true and new-infections = 0]
17
1
11

INPUTBOX
817
393
897
453
num-year-trans
24.0
1
0
Number

INPUTBOX
765
461
920
521
goal
1.0
1
0
Number

INPUTBOX
953
13
1057
73
prep-effectiveness
0.0
1
0
Number

INPUTBOX
961
74
1058
134
prep-cov-positive
0.0
1
0
Number

INPUTBOX
864
14
951
74
prep-cov-casual
0.0
1
0
Number

INPUTBOX
853
75
965
135
prep-cov-concurrent
0.0
1
0
Number

INPUTBOX
1074
174
1229
234
dry-run
15.0
1
0
Number

BUTTON
1201
416
1267
449
Profile
profile
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
1112
471
1228
504
RunExperiment
RunExperiment
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

INPUTBOX
1165
292
1320
352
maxRun
10.0
1
0
Number

BUTTON
1157
533
1257
566
Optimization
Optimization
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
1062
536
1145
569
NIL
OptPolicy\n
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

@#$#@#$#@
## WHAT IS IT?

This section could give a general understanding of what the model is trying to show or explain.

## HOW IT WORKS

This section could explain what rules the agents use to create the overall behavior of the model.

## HOW TO USE IT

This section could explain how to use the model, including a description of each of the items in the interface tab.  
Initially hit "setup" button on the interface tab

1. It sets up global variables by calling "setup-globals"
	a. globals are all the data that remains the same for entire population

2. It calls "setup-people"
 	a. It generates number of people as mentioned in the "number-people" input button. Sets x% (currently 100%) of the initial people as index-patients. Which means everyone gets infected in quarter 1, i.e., tick 1 (but are un-infected in tick 0 for ease of computation). 

 	b. Initializes all the variable used in the model by calling procedure "set-infected-variables"

Next hit the "go" button. This begins the simulation

1. For "simulation-years" updates all the variables of (dead =0, i.e, non-dead) people in the simulation by calling "update-simulation"

2. Each quarter, i.e., each tick, creates new infections (currently creates new people because 100% of initial population was infected in the beginning and can be changed as needed). Number of new infections = total number of transmissions generated by all the index patients only. 
	a. This is done by calling the procedure "setup-new-transmissions [number]".

	b. The procedure sets the new infections as index-patients = false and calls "set-infected-variables" to initialize the variables. From the next quarter they are included in the simulation, that is, "update-simulation" automatically applies to everyone in the simulation

3. when a person dies, variable "dead = 1" but we do not assign "die" which is in-built netlogo function for permanently removing person from the simulation. This is done so that the population statistics can be collected in the end (using die erases persons data)

After simulation stops hit "display-values"  
1. Displays the required data for index and transmissions separately.  
2. For each peron, at time of death, "set-life-variables" which keeps track of life variables. When display-values is clicked the simulation is modeled to display some of these values. Note: Currently all life-variables are for index-patients ONLY. Change as needed in procedures "set-dead", "set-life-variables", and "display-values"

## THINGS TO NOTICE

This section could give some ideas of things for the user to notice while running the model.

## THINGS TO TRY

This section could give some ideas of things for the user to try to do (move sliders, switches, etc.) with the model.

## EXTENDING THE MODEL

This section could give some ideas of things to add or change in the procedures tab to make the model more complicated, detailed, accurate, etc.

## NETLOGO FEATURES

This section could point out any especially interesting or unusual features of NetLogo that the model makes use of, particularly in the Procedures tab.  It might also point out places where workarounds were needed because of missing features.

## RELATED MODELS

This section could give the names of models in the NetLogo Models Library or elsewhere which are of related interest.

## CREDITS AND REFERENCES

This section could contain a reference to the model's URL on the web if it has one, as well as any other necessary credits or references.
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
0
Rectangle -7500403 true true 151 225 180 285
Rectangle -7500403 true true 47 225 75 285
Rectangle -7500403 true true 15 75 210 225
Circle -7500403 true true 135 75 150
Circle -16777216 true false 165 76 116

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

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.0.2
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment" repetitions="1" runMetricsEveryStep="false">
    <setup>show date-and-time
setup
;clear-all
;import-world "Base Model-HET MSM world.csv"</setup>
    <go>go</go>
    <final>;write-life-variables
show date-and-time
show numActsCasualMSM
print  numActsMainMSM
print  numActsConMSM
print  numActsMainHET
print  numActsConHET</final>
    <exitCondition>;count people with [dead = 0 and index-patient? = false and infected? = true] = 0 and ticks &gt; sim-dry-run + time-unit * num-year-trans
ticks &gt; (sim-dry-run + time-unit * num-year-trans)
;count people with [dead = 0 and infected-2013-2022? = true] = 0 and ticks &gt; sim-dry-run + time-unit * 20;; at least past 2011</exitCondition>
    <enumeratedValueSet variable="goal">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prep-effectiveness">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prep-cov-casual">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prep-cov-positive">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prep-cov-concurrent">
      <value value="0"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment2" repetitions="1" runMetricsEveryStep="false">
    <setup>show date-and-time
setup
;clear-all
;import-world "BaseModel-HETMSM world-10000-6-20-2015"
setData</setup>
    <go>go</go>
    <final>;write-life-variables
show date-and-time
show numActsCasualMSM
print  numActsMainMSM
print  numActsConMSM
print  numActsMainHET
print  numActsConHET</final>
    <exitCondition>;count people with [dead = 0 and index-patient? = false and infected? = true] = 0 and ticks &gt; sim-dry-run + time-unit * num-year-trans
ticks &gt; (sim-dry-run + time-unit * num-year-trans)
;count people with [dead = 0 and infected-2013-2022? = true] = 0 and ticks &gt; sim-dry-run + time-unit * 20;; at least past 2011</exitCondition>
    <enumeratedValueSet variable="goal">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prep-effectiveness">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prep-cov-casual">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prep-cov-positive">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prep-cov-concurrent">
      <value value="0"/>
    </enumeratedValueSet>
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
0
@#$#@#$#@
