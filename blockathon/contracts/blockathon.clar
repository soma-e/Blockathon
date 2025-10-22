;; Decentralized Hackathon Platform
;; A platform for organizing hackathons with automated registration,
;; project submissions, transparent judging, and prize distribution

;; SIP-010 token trait - using the standard trait definition
(define-trait sip-010-trait
  (
    (transfer (uint principal principal (optional (buff 34))) (response bool uint))
    (get-name () (response (string-ascii 32) uint))
    (get-symbol () (response (string-ascii 32) uint))
    (get-decimals () (response uint uint))
    (get-balance (principal) (response uint uint))
    (get-total-supply () (response uint uint))
    (get-token-uri () (response (optional (string-utf8 256)) uint))
  )
)

;; Constants
(define-constant ERR-NOT-FOUND (err u404))
(define-constant ERR-UNAUTHORIZED (err u401))
(define-constant ERR-INVALID-INPUT (err u400))
(define-constant ERR-ALREADY-EXISTS (err u409))
(define-constant ERR-DEADLINE-PASSED (err u410))
(define-constant ERR-INVALID-STATUS (err u411))
(define-constant ERR-INSUFFICIENT-FUNDS (err u412))
(define-constant ERR-MAX-REACHED (err u413))

;; Hackathon events
(define-map hackathons
  { hackathon-id: uint }
  {
    name: (string-utf8 128),
    description: (string-utf8 1024),
    organizer: principal,
    created-at: uint,
    registration-start: uint,
    registration-end: uint,
    event-start: uint,
    event-end: uint,
    submission-deadline: uint,
    tracks: (list 10 (string-ascii 64)),
    prize-pool: uint,
    token-type: (string-ascii 8),
    token-contract: (optional principal),
    max-team-size: uint,
    max-participants: uint,
    current-participants: uint,
    website-url: (optional (string-utf8 256)),
    rules-hash: (buff 32),
    status: (string-ascii 16),
    judging-mechanism: (string-ascii 32)
  }
)

;; Hackathon participants
(define-map participants
  { hackathon-id: uint, participant-principal: principal }
  {
    registered-at: uint,
    team-identifier: (optional uint),
    skills: (list 10 (string-ascii 32)),
    registration-status: (string-ascii 16),
    on-chain-identity: (optional (string-ascii 64)),
    contact-info-hash: (buff 32),
    attended: bool
  }
)

;; Teams
(define-map teams
  { hackathon-id: uint, team-identifier: uint }
  {
    name: (string-utf8 64),
    description: (string-utf8 512),
    created-at: uint,
    founder: principal,
    members: (list 10 principal),
    project-identifier: (optional uint),
    track-selections: (list 3 (string-ascii 64)),
    team-website: (optional (string-utf8 256)),
    team-repository: (optional (string-utf8 256)),
    logo-hash: (optional (buff 32))
  }
)

;; Project submissions
(define-map projects
  { hackathon-id: uint, project-identifier: uint }
  {
    team-identifier: uint,
    title: (string-utf8 128),
    description: (string-utf8 1024),
    submitted-at: uint,
    last-updated: uint,
    submission-hash: (buff 32),
    repository-url: (string-utf8 256),
    demo-url: (optional (string-utf8 256)),
    tracks: (list 3 (string-ascii 64)),
    technologies: (list 10 (string-ascii 32)),
    status: (string-ascii 16),
    disqualification-reason: (optional (string-utf8 256)),
    average-score: (optional uint),
    final-rank: (optional uint),
    prize-amount: (optional uint)
  }
)

;; Judges
(define-map judges
  { hackathon-id: uint, judge-principal: principal }
  {
    name: (string-utf8 64),
    bio: (string-utf8 512),
    added-at: uint,
    added-by: principal,
    tracks: (list 5 (string-ascii 64)),
    expertise: (list 5 (string-ascii 32)),
    conflicts: (list 10 principal),
    status: (string-ascii 16),
    projects-assigned: (list 30 uint),
    projects-scored: uint,
    judge-weight: uint
  }
)

;; Judge scores
(define-map scores
  { hackathon-id: uint, project-identifier: uint, judge-principal: principal }
  {
    scores: (list 10 (tuple (category (string-ascii 32)) (score uint))),
    feedback: (string-utf8 512),
    submitted-at: uint,
    total-score: uint,
    weighted-score: uint
  }
)

;; Prizes
(define-map prizes
  { hackathon-id: uint, prize-identifier: uint }
  {
    title: (string-utf8 64),
    description: (string-utf8 256),
    track: (optional (string-ascii 64)),
    amount: uint,
    sponsor: (optional principal),
    winner-project-id: (optional uint),
    claimed: bool,
    claimed-at: (optional uint),
    claimed-by: (optional principal)
  }
)

;; Sponsors
(define-map sponsors
  { hackathon-id: uint, sponsor: principal }
  {
    name: (string-utf8 64),
    website: (optional (string-utf8 256)),
    logo-hash: (optional (buff 32)),
    contribution-amount: uint,
    contributed-at: uint,
    sponsor-tier: (string-ascii 16),
    custom-prizes: (list 5 uint)
  }
)

;; Event activity log
(define-map event-activity
  { hackathon-id: uint, activity-identifier: uint }
  {
    activity-type: (string-ascii 32),
    actor: principal,
    timestamp: uint,
    details: (string-utf8 256),
    related-data: (optional (buff 32))
  }
)

;; Next available IDs
(define-data-var next-hackathon-id uint u1)
(define-map next-team-id { hackathon-id: uint } { id: uint })
(define-map next-project-id { hackathon-id: uint } { id: uint })
(define-map next-prize-id { hackathon-id: uint } { id: uint })
(define-map next-activity-id { hackathon-id: uint } { id: uint })

;; Protocol configuration
(define-data-var platform-fee-percentage uint u200)
(define-data-var fee-recipient principal tx-sender)
(define-data-var min-prize-percentage uint u8000)

;; Create a new hackathon event
(define-public (create-hackathon
                (name (string-utf8 128))
                (description (string-utf8 1024))
                (registration-start uint)
                (registration-end uint)
                (event-start uint)
                (event-end uint)
                (submission-deadline uint)
                (tracks (list 10 (string-ascii 64)))
                (prize-pool uint)
                (token-type (string-ascii 8))
                (token-contract (optional principal))
                (max-team-size uint)
                (max-participants uint)
                (website-url (optional (string-utf8 256)))
                (rules-hash (buff 32))
                (judging-mechanism (string-ascii 32)))
  (let
    ((hackathon-id (var-get next-hackathon-id)))
    
    ;; Validate parameters
    (asserts! (> (len tracks) u0) ERR-INVALID-INPUT)
    (asserts! (< registration-start registration-end) ERR-INVALID-INPUT)
    (asserts! (< registration-end event-start) ERR-INVALID-INPUT)
    (asserts! (< event-start event-end) ERR-INVALID-INPUT)
    (asserts! (<= event-end submission-deadline) ERR-INVALID-INPUT)
    (asserts! (> max-team-size u0) ERR-INVALID-INPUT)
    (asserts! (> max-participants u0) ERR-INVALID-INPUT)
    (asserts! (is-valid-token-type token-type) ERR-INVALID-INPUT)
    (asserts! (or (is-eq token-type "STX") (is-some token-contract)) ERR-INVALID-INPUT)
    (asserts! (is-valid-judging-mechanism judging-mechanism) ERR-INVALID-INPUT)
    (asserts! (> prize-pool u0) ERR-INVALID-INPUT)
    
    ;; Create the hackathon event
    (map-set hackathons
      { hackathon-id: hackathon-id }
      {
        name: name,
        description: description,
        organizer: tx-sender,
        created-at: block-height,
        registration-start: registration-start,
        registration-end: registration-end,
        event-start: event-start,
        event-end: event-end,
        submission-deadline: submission-deadline,
        tracks: tracks,
        prize-pool: prize-pool,
        token-type: token-type,
        token-contract: token-contract,
        max-team-size: max-team-size,
        max-participants: max-participants,
        current-participants: u0,
        website-url: website-url,
        rules-hash: rules-hash,
        status: "upcoming",
        judging-mechanism: judging-mechanism
      }
    )
    
    ;; Initialize counters
    (map-set next-team-id { hackathon-id: hackathon-id } { id: u1 })
    (map-set next-project-id { hackathon-id: hackathon-id } { id: u1 })
    (map-set next-prize-id { hackathon-id: hackathon-id } { id: u1 })
    (map-set next-activity-id { hackathon-id: hackathon-id } { id: u1 })
    
    ;; Log activity
    (try! (log-event-activity hackathon-id "event-created" tx-sender u"Hackathon event created" none))
    
    ;; Fund the prize pool if STX token type
    (try!
      (if (is-eq token-type "STX")
          (fund-prize-pool-stx hackathon-id prize-pool)
          (ok true)
      )
    )
    
    ;; Increment hackathon ID counter
    (var-set next-hackathon-id (+ hackathon-id u1))
    
    (ok hackathon-id)
  )
)

;; Check if token type is valid
(define-private (is-valid-token-type (token-type (string-ascii 8)))
  (or (is-eq token-type "STX")
      (is-eq token-type "SIP010"))
)

;; Check if judging mechanism is valid
(define-private (is-valid-judging-mechanism (mechanism (string-ascii 32)))
  (or (is-eq mechanism "panel")
      (or (is-eq mechanism "community")
          (is-eq mechanism "hybrid")))
)

;; Log event activity
(define-private (log-event-activity
                (hackathon-id uint)
                (activity-type (string-ascii 32))
                (actor principal)
                (details (string-utf8 256))
                (related-data (optional (buff 32))))
  (let
    ((activity-counter-data (unwrap! (map-get? next-activity-id { hackathon-id: hackathon-id })
                                ERR-NOT-FOUND))
     (activity-identifier (get id activity-counter-data)))
    
    ;; Create activity log entry
    (map-set event-activity
      { hackathon-id: hackathon-id, activity-identifier: activity-identifier }
      {
        activity-type: activity-type,
        actor: actor,
        timestamp: block-height,
        details: details,
        related-data: related-data
      }
    )
    
    ;; Increment activity counter
    (map-set next-activity-id
      { hackathon-id: hackathon-id }
      { id: (+ activity-identifier u1) }
    )
    
    (ok activity-identifier)
  )
)

;; Fund prize pool with STX
(define-public (fund-prize-pool-stx (hackathon-id uint) (amount uint))
  (let
    ((hackathon-record (unwrap! (map-get? hackathons { hackathon-id: hackathon-id })
                         ERR-NOT-FOUND)))
    
    ;; Validate
    (asserts! (is-eq tx-sender (get organizer hackathon-record)) ERR-UNAUTHORIZED)
    (asserts! (is-eq (get token-type hackathon-record) "STX") ERR-INVALID-INPUT)
    (asserts! (> amount u0) ERR-INVALID-INPUT)
    
    ;; Calculate platform fee
    (let
      ((platform-fee (/ (* amount (var-get platform-fee-percentage)) u10000)))
      
      ;; Transfer STX from funder to contract
      (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
      
      ;; Transfer platform fee
      (try! (as-contract (stx-transfer? platform-fee tx-sender (var-get fee-recipient))))
      
      ;; Log activity
      (try! (log-event-activity hackathon-id "prize-pool-funded" tx-sender
                               u"Prize pool funded with STX" none))
      
      (ok true)
    )
  )
)

;; Fund prize pool with SIP-010 tokens
(define-public (fund-prize-pool-ft
                (hackathon-id uint)
                (token-contract <sip-010-trait>)
                (amount uint))
  (let
    ((hackathon-record (unwrap! (map-get? hackathons { hackathon-id: hackathon-id })
                         ERR-NOT-FOUND)))
    
    ;; Validate
    (asserts! (is-eq tx-sender (get organizer hackathon-record)) ERR-UNAUTHORIZED)
    (asserts! (is-eq (get token-type hackathon-record) "SIP010") ERR-INVALID-INPUT)
    (asserts! (is-some (get token-contract hackathon-record)) ERR-INVALID-INPUT)
    (asserts! (is-eq (unwrap-panic (get token-contract hackathon-record)) (contract-of token-contract)) ERR-INVALID-INPUT)
    (asserts! (> amount u0) ERR-INVALID-INPUT)
    
    ;; Calculate platform fee
    (let
      ((platform-fee (/ (* amount (var-get platform-fee-percentage)) u10000)))
      
      ;; Transfer tokens from funder to contract
      (try! (contract-call? token-contract transfer amount tx-sender (as-contract tx-sender) none))
      
      ;; Transfer platform fee
      (try! (as-contract (contract-call? token-contract transfer platform-fee tx-sender (var-get fee-recipient) none)))
      
      ;; Log activity
      (try! (log-event-activity hackathon-id "prize-pool-funded" tx-sender
                               u"Prize pool funded with tokens" none))
      
      (ok true)
    )
  )
)

;; Update hackathon status
(define-public (update-hackathon-status (hackathon-id uint) (new-status (string-ascii 16)))
  (let
    ((hackathon-record (unwrap! (map-get? hackathons { hackathon-id: hackathon-id })
                         ERR-NOT-FOUND)))
    
    ;; Validate
    (asserts! (is-eq tx-sender (get organizer hackathon-record)) ERR-UNAUTHORIZED)
    (asserts! (is-valid-hackathon-status new-status) ERR-INVALID-INPUT)
    
    ;; Update status
    (map-set hackathons
      { hackathon-id: hackathon-id }
      (merge hackathon-record { status: new-status })
    )
    
    ;; Log activity
    (try! (log-event-activity hackathon-id "status-updated" tx-sender
                           u"Status updated" none))
    
    (ok true)
  )
)

;; Check if hackathon status is valid
(define-private (is-valid-hackathon-status (status (string-ascii 16)))
  (or (is-eq status "upcoming")
      (or (is-eq status "registration")
          (or (is-eq status "active")
              (or (is-eq status "judging")
                  (or (is-eq status "completed")
                      (is-eq status "cancelled"))))))
)

;; Register as a participant
(define-public (register-as-participant
                (hackathon-id uint)
                (skills (list 10 (string-ascii 32)))
                (on-chain-identity (optional (string-ascii 64)))
                (contact-info-hash (buff 32)))
  (let
    ((hackathon-record (unwrap! (map-get? hackathons { hackathon-id: hackathon-id })
                         ERR-NOT-FOUND)))
    
    ;; Validate
    (asserts! (is-eq (get status hackathon-record) "registration") ERR-INVALID-STATUS)
    (asserts! (< (get current-participants hackathon-record) (get max-participants hackathon-record)) ERR-MAX-REACHED)
    (asserts! (>= block-height (get registration-start hackathon-record)) ERR-DEADLINE-PASSED)
    (asserts! (<= block-height (get registration-end hackathon-record)) ERR-DEADLINE-PASSED)
    (asserts! (is-none (map-get? participants { hackathon-id: hackathon-id, participant-principal: tx-sender })) ERR-ALREADY-EXISTS)
    
    ;; Register participant
    (map-set participants
      { hackathon-id: hackathon-id, participant-principal: tx-sender }
      {
        registered-at: block-height,
        team-identifier: none,
        skills: skills,
        registration-status: "registered",
        on-chain-identity: on-chain-identity,
        contact-info-hash: contact-info-hash,
        attended: false
      }
    )
    
    ;; Update participant count
    (map-set hackathons
      { hackathon-id: hackathon-id }
      (merge hackathon-record 
        { current-participants: (+ (get current-participants hackathon-record) u1) }
      )
    )
    
    ;; Log activity
    (try! (log-event-activity hackathon-id "participant-registered" tx-sender
                            u"New participant registered" none))
    
    (ok true)
  )
)

;; Create a team
(define-public (create-team
                (hackathon-id uint)
                (name (string-utf8 64))
                (description (string-utf8 512))
                (track-selections (list 3 (string-ascii 64)))
                (team-website (optional (string-utf8 256)))
                (team-repository (optional (string-utf8 256)))
                (logo-hash (optional (buff 32))))
  (let
    ((hackathon-record (unwrap! (map-get? hackathons { hackathon-id: hackathon-id })
                         ERR-NOT-FOUND))
     (participant-record (unwrap! (map-get? participants { hackathon-id: hackathon-id, participant-principal: tx-sender })
                           ERR-NOT-FOUND))
     (team-counter-data (unwrap! (map-get? next-team-id { hackathon-id: hackathon-id })
                            ERR-NOT-FOUND))
     (team-identifier (get id team-counter-data)))
    
    ;; Validate
    (asserts! (or (is-eq (get status hackathon-record) "registration")
                 (is-eq (get status hackathon-record) "active")) ERR-INVALID-STATUS)
    (asserts! (is-none (get team-identifier participant-record)) ERR-ALREADY-EXISTS)
    (asserts! (> (len track-selections) u0) ERR-INVALID-INPUT)
    (asserts! (> (len name) u0) ERR-INVALID-INPUT)
    
    ;; Validate track selections exist in hackathon
    (try! (validate-tracks hackathon-id track-selections))
    
    ;; Create the team
    (map-set teams
      { hackathon-id: hackathon-id, team-identifier: team-identifier }
      {
        name: name,
        description: description,
        created-at: block-height,
        founder: tx-sender,
        members: (list tx-sender),
        project-identifier: none,
        track-selections: track-selections,
        team-website: team-website,
        team-repository: team-repository,
        logo-hash: logo-hash
      }
    )
    
    ;; Update participant record
    (map-set participants
      { hackathon-id: hackathon-id, participant-principal: tx-sender }
      (merge participant-record 
        {
          team-identifier: (some team-identifier),
          registration-status: "teamed"
        }
      )
    )
    
    ;; Increment team ID counter
    (map-set next-team-id
      { hackathon-id: hackathon-id }
      { id: (+ team-identifier u1) }
    )
    
    ;; Log activity
    (try! (log-event-activity hackathon-id "team-created" tx-sender
                            u"New team created" none))
    
    (ok team-identifier)
  )
)

;; Validate that all tracks exist in the hackathon
(define-private (validate-tracks (hackathon-id uint) (track-selections (list 3 (string-ascii 64))))
  (let
    ((hackathon-record (unwrap! (map-get? hackathons { hackathon-id: hackathon-id })
                         ERR-NOT-FOUND)))
    
    ;; Check each track selection
    (asserts! (get valid (fold check-track-in-list track-selections { tracks: (get tracks hackathon-record), valid: true }))
              ERR-INVALID-INPUT)
    
    (ok true)
  )
)

;; Helper function to check if a track exists in the hackathon tracks
(define-private (check-track-in-list 
                (track (string-ascii 64)) 
                (accumulator { tracks: (list 10 (string-ascii 64)), valid: bool }))
  (if (get valid accumulator)
      { tracks: (get tracks accumulator), valid: (get found (fold check-track-match (get tracks accumulator) { target: track, found: false })) }
      accumulator)
)

;; Helper to check track match
(define-private (check-track-match 
                (track-to-check (string-ascii 64))
                (accumulator { target: (string-ascii 64), found: bool }))
  (if (get found accumulator)
      accumulator
      { target: (get target accumulator), found: (is-eq track-to-check (get target accumulator)) })
)

;; Join a team
(define-public (join-team (hackathon-id uint) (team-identifier uint))
  (let
    ((hackathon-record (unwrap! (map-get? hackathons { hackathon-id: hackathon-id })
                         ERR-NOT-FOUND))
     (participant-record (unwrap! (map-get? participants { hackathon-id: hackathon-id, participant-principal: tx-sender })
                           ERR-NOT-FOUND))
     (team-record (unwrap! (map-get? teams { hackathon-id: hackathon-id, team-identifier: team-identifier })
                    ERR-NOT-FOUND)))
    
    ;; Validate
    (asserts! (or (is-eq (get status hackathon-record) "registration")
                 (is-eq (get status hackathon-record) "active")) ERR-INVALID-STATUS)
    (asserts! (is-none (get team-identifier participant-record)) ERR-ALREADY-EXISTS)
    (asserts! (< (len (get members team-record)) (get max-team-size hackathon-record)) ERR-MAX-REACHED)
    
    ;; Add member to team
    (let
      ((new-members-list (unwrap! (as-max-len? (append (get members team-record) tx-sender) u10)
                                ERR-MAX-REACHED)))
      
      (map-set teams
        { hackathon-id: hackathon-id, team-identifier: team-identifier }
        (merge team-record { members: new-members-list })
      )
      
      ;; Update participant record
      (map-set participants
        { hackathon-id: hackathon-id, participant-principal: tx-sender }
        (merge participant-record 
          {
            team-identifier: (some team-identifier),
            registration-status: "teamed"
          }
        )
      )
      
      ;; Log activity
      (try! (log-event-activity hackathon-id "team-joined" tx-sender
                              u"Participant joined a team" none))
      
      (ok true)
    )
  )
)

;; Submit a project
(define-public (submit-project
                (hackathon-id uint)
                (team-identifier uint)
                (title (string-utf8 128))
                (description (string-utf8 1024))
                (submission-hash (buff 32))
                (repository-url (string-utf8 256))
                (demo-url (optional (string-utf8 256)))
                (tracks (list 3 (string-ascii 64)))
                (technologies (list 10 (string-ascii 32))))
  (let
    ((hackathon-record (unwrap! (map-get? hackathons { hackathon-id: hackathon-id })
                         ERR-NOT-FOUND))
     (team-record (unwrap! (map-get? teams { hackathon-id: hackathon-id, team-identifier: team-identifier })
                    ERR-NOT-FOUND))
     (project-counter-data (unwrap! (map-get? next-project-id { hackathon-id: hackathon-id })
                               ERR-NOT-FOUND))
     (project-identifier (get id project-counter-data)))
    
    ;; Validate
    (asserts! (is-member-of-team tx-sender (get members team-record)) ERR-UNAUTHORIZED)
    (asserts! (or (is-eq (get status hackathon-record) "active")
                 (and (<= block-height (get submission-deadline hackathon-record))
                      (> block-height (get event-end hackathon-record)))) ERR-INVALID-STATUS)
    (asserts! (is-none (get project-identifier team-record)) ERR-ALREADY-EXISTS)
    (asserts! (> (len tracks) u0) ERR-INVALID-INPUT)
    (asserts! (> (len title) u0) ERR-INVALID-INPUT)
    (asserts! (> (len repository-url) u0) ERR-INVALID-INPUT)
    
    ;; Create the project
    (map-set projects
      { hackathon-id: hackathon-id, project-identifier: project-identifier }
      {
        team-identifier: team-identifier,
        title: title,
        description: description,
        submitted-at: block-height,
        last-updated: block-height,
        submission-hash: submission-hash,
        repository-url: repository-url,
        demo-url: demo-url,
        tracks: tracks,
        technologies: technologies,
        status: "submitted",
        disqualification-reason: none,
        average-score: none,
        final-rank: none,
        prize-amount: none
      }
    )
    
    ;; Update team record
    (map-set teams
      { hackathon-id: hackathon-id, team-identifier: team-identifier }
      (merge team-record { project-identifier: (some project-identifier) })
    )
    
    ;; Increment project ID counter
    (map-set next-project-id
      { hackathon-id: hackathon-id }
      { id: (+ project-identifier u1) }
    )
    
    ;; Log activity
    (try! (log-event-activity hackathon-id "project-submitted" tx-sender
                            u"Project submitted" (some submission-hash)))
    
    (ok project-identifier)
  )
)

;; Check if a principal is a member of a team
(define-private (is-member-of-team (team-member principal) (members (list 10 principal)))
  (get found (fold check-member-match members { target: team-member, found: false }))
)

;; Helper to check member match
(define-private (check-member-match 
                (member-to-check principal)
                (accumulator { target: principal, found: bool }))
  (if (get found accumulator)
      accumulator
      { target: (get target accumulator), found: (is-eq member-to-check (get target accumulator)) })
)

;; Add a judge
(define-public (add-judge
                (hackathon-id uint)
                (judge-principal principal)
                (name (string-utf8 64))
                (bio (string-utf8 512))
                (tracks (list 5 (string-ascii 64)))
                (expertise (list 5 (string-ascii 32)))
                (judge-weight uint))
  (let
    ((hackathon-record (unwrap! (map-get? hackathons { hackathon-id: hackathon-id })
                         ERR-NOT-FOUND)))
    
    ;; Validate
    (asserts! (is-eq tx-sender (get organizer hackathon-record)) ERR-UNAUTHORIZED)
    (asserts! (> (len tracks) u0) ERR-INVALID-INPUT)
    (asserts! (and (>= judge-weight u1) (<= judge-weight u10)) ERR-INVALID-INPUT)
    (asserts! (> (len name) u0) ERR-INVALID-INPUT)
    
    ;; Add the judge
    (map-set judges
      { hackathon-id: hackathon-id, judge-principal: judge-principal }
      {
        name: name,
        bio: bio,
        added-at: block-height,
        added-by: tx-sender,
        tracks: tracks,
        expertise: expertise,
        conflicts: (list),
        status: "invited",
        projects-assigned: (list),
        projects-scored: u0,
        judge-weight: judge-weight
      }
    )
    
    ;; Log activity
    (try! (log-event-activity hackathon-id "judge-added" tx-sender
                            u"Judge added to event" none))
    
    (ok true)
  )
)

;; Accept judge invitation
(define-public (accept-judge-invitation (hackathon-id uint))
  (let
    ((judge-record (unwrap! (map-get? judges { hackathon-id: hackathon-id, judge-principal: tx-sender })
                          ERR-NOT-FOUND)))
    
    ;; Validate
    (asserts! (is-eq (get status judge-record) "invited") ERR-INVALID-STATUS)
    
    ;; Update judge status
    (map-set judges
      { hackathon-id: hackathon-id, judge-principal: tx-sender }
      (merge judge-record { status: "accepted" })
    )
    
    ;; Log activity
    (try! (log-event-activity hackathon-id "judge-accepted" tx-sender
                            u"Judge accepted invitation" none))
    
    (ok true)
  )
)

;; Submit scores for a project
(define-public (submit-scores
                (hackathon-id uint)
                (project-identifier uint)
                (score-items (list 10 (tuple (category (string-ascii 32)) (score uint))))
                (feedback (string-utf8 512)))
  (let
    ((hackathon-record (unwrap! (map-get? hackathons { hackathon-id: hackathon-id })
                         ERR-NOT-FOUND))
     (judge-record (unwrap! (map-get? judges { hackathon-id: hackathon-id, judge-principal: tx-sender })
                          ERR-NOT-FOUND))
     (project-record (unwrap! (map-get? projects { hackathon-id: hackathon-id, project-identifier: project-identifier })
                       ERR-NOT-FOUND)))
    
    ;; Validate
    (asserts! (is-eq (get status hackathon-record) "judging") ERR-INVALID-STATUS)
    (asserts! (is-eq (get status judge-record) "active") ERR-INVALID-STATUS)
    (asserts! (is-project-assigned-to-judge project-identifier (get projects-assigned judge-record)) ERR-UNAUTHORIZED)
    (asserts! (> (len score-items) u0) ERR-INVALID-INPUT)
    
    ;; Calculate total score
    (let
      ((total-score (calculate-total-score score-items))
       (weighted-score (* total-score (get judge-weight judge-record))))
      
      ;; Record the scores
      (map-set scores
        { hackathon-id: hackathon-id, project-identifier: project-identifier, judge-principal: tx-sender }
        {
          scores: score-items,
          feedback: feedback,
          submitted-at: block-height,
          total-score: total-score,
          weighted-score: weighted-score
        }
      )
      
      ;; Update judge's scored count
      (map-set judges
        { hackathon-id: hackathon-id, judge-principal: tx-sender }
        (merge judge-record 
          { projects-scored: (+ (get projects-scored judge-record) u1) }
        )
      )
      
      ;; Log activity
      (try! (log-event-activity hackathon-id "scores-submitted" tx-sender
                              u"Scores submitted for project" none))
      
      (ok true)
    )
  )
)

;; Check if project is assigned to judge
(define-private (is-project-assigned-to-judge (project-identifier uint) (assigned-project-list (list 30 uint)))
  (get found (fold check-project-assignment assigned-project-list { target: project-identifier, found: false }))
)

;; Helper to check project assignment
(define-private (check-project-assignment 
                (project-to-check uint)
                (accumulator { target: uint, found: bool }))
  (if (get found accumulator)
      accumulator
      { target: (get target accumulator), found: (is-eq project-to-check (get target accumulator)) })
)

;; Calculate total score from score list
(define-private (calculate-total-score (score-items (list 10 (tuple (category (string-ascii 32)) (score uint)))))
  ;; Sum all scores in the list
  (get total (fold sum-scores score-items { total: u0 }))
)

;; Helper to sum scores
(define-private (sum-scores 
                (score-item (tuple (category (string-ascii 32)) (score uint)))
                (accumulator { total: uint }))
  { total: (+ (get total accumulator) (get score score-item)) }
)

;; Add a prize
(define-public (add-prize
                (hackathon-id uint)
                (title (string-utf8 64))
                (description (string-utf8 256))
                (track (optional (string-ascii 64)))
                (amount uint)
                (sponsor (optional principal)))
  (let
    ((hackathon-record (unwrap! (map-get? hackathons { hackathon-id: hackathon-id })
                         ERR-NOT-FOUND))
     (prize-counter-data (unwrap! (map-get? next-prize-id { hackathon-id: hackathon-id })
                             ERR-NOT-FOUND))
     (prize-identifier (get id prize-counter-data)))
    
    ;; Validate
    (asserts! (is-eq tx-sender (get organizer hackathon-record)) ERR-UNAUTHORIZED)
    (asserts! (or (is-eq (get status hackathon-record) "upcoming")
                 (is-eq (get status hackathon-record) "registration")
                 (is-eq (get status hackathon-record) "active")) ERR-INVALID-STATUS)
    (asserts! (> amount u0) ERR-INVALID-INPUT)
    (asserts! (> (len title) u0) ERR-INVALID-INPUT)
    
    ;; If track provided, validate it exists
    (if (is-some track)
        (asserts! (get found (fold check-track-match (get tracks hackathon-record) { target: (unwrap-panic track), found: false })) ERR-INVALID-INPUT)
        true
    )
    
    ;; Create the prize
    (map-set prizes
      { hackathon-id: hackathon-id, prize-identifier: prize-identifier }
      {
        title: title,
        description: description,
        track: track,
        amount: amount,
        sponsor: sponsor,
        winner-project-id: none,
        claimed: false,
        claimed-at: none,
        claimed-by: none
      }
    )
    
    ;; Increment prize ID counter
    (map-set next-prize-id
      { hackathon-id: hackathon-id }
      { id: (+ prize-identifier u1) }
    )
    
    ;; Log activity
    (try! (log-event-activity hackathon-id "prize-added" tx-sender
                            u"Prize added to event" none))
    
    (ok prize-identifier)
  )
)

;; Claim a prize
(define-public (claim-prize (hackathon-id uint) (prize-identifier uint))
  (let
    ((hackathon-record (unwrap! (map-get? hackathons { hackathon-id: hackathon-id })
                         ERR-NOT-FOUND))
     (prize-record (unwrap! (map-get? prizes { hackathon-id: hackathon-id, prize-identifier: prize-identifier })
                     ERR-NOT-FOUND))
     (project-identifier (unwrap! (get winner-project-id prize-record) ERR-NOT-FOUND))
     (project-record (unwrap! (map-get? projects { hackathon-id: hackathon-id, project-identifier: project-identifier })
                       ERR-NOT-FOUND))
     (team-record (unwrap! (map-get? teams { hackathon-id: hackathon-id, team-identifier: (get team-identifier project-record) })
                    ERR-NOT-FOUND)))
    
    ;; Validate
    (asserts! (is-eq (get status hackathon-record) "completed") ERR-INVALID-STATUS)
    (asserts! (not (get claimed prize-record)) ERR-ALREADY-EXISTS)
    (asserts! (is-member-of-team tx-sender (get members team-record)) ERR-UNAUTHORIZED)
    
    ;; Mark prize as claimed
    (map-set prizes
      { hackathon-id: hackathon-id, prize-identifier: prize-identifier }
      (merge prize-record 
        {
          claimed: true,
          claimed-at: (some block-height),
          claimed-by: (some tx-sender)
        }
      )
    )
    
    ;; Transfer prize funds
    (try! (transfer-prize-funds hackathon-id prize-identifier tx-sender (get amount prize-record)))
    
    ;; Log activity
    (try! (log-event-activity hackathon-id "prize-claimed" tx-sender
                            u"Prize claimed by winner" none))
    
    (ok true)
  )
)

;; Transfer prize funds to winner
(define-private (transfer-prize-funds
                 (hackathon-id uint)
                 (prize-identifier uint)
                (recipient principal)
                (amount uint))
  (let
    ((hackathon-record (unwrap! (map-get? hackathons { hackathon-id: hackathon-id })
                         ERR-NOT-FOUND)))
    
    ;; Transfer based on token type
    (if (is-eq (get token-type hackathon-record) "STX")
        ;; Transfer STX
        (as-contract (stx-transfer? amount tx-sender recipient))
        ;; For SIP-010 tokens, would need the token contract
        ;; Simplified for this example
        (ok true)
    )
  )
)

;; Read-only functions

;; Get hackathon details
(define-read-only (get-hackathon-details (hackathon-id uint))
  (ok (unwrap! (map-get? hackathons { hackathon-id: hackathon-id })
              ERR-NOT-FOUND))
)

;; Get participant details
(define-read-only (get-participant-details (hackathon-id uint) (participant-principal principal))
  (ok (unwrap! (map-get? participants { hackathon-id: hackathon-id, participant-principal: participant-principal })
              ERR-NOT-FOUND))
)

;; Get team details
(define-read-only (get-team-details (hackathon-id uint) (team-identifier uint))
  (ok (unwrap! (map-get? teams { hackathon-id: hackathon-id, team-identifier: team-identifier })
              ERR-NOT-FOUND))
)

;; Get project details
(define-read-only (get-project-details (hackathon-id uint) (project-identifier uint))
  (ok (unwrap! (map-get? projects { hackathon-id: hackathon-id, project-identifier: project-identifier })
              ERR-NOT-FOUND))
)

;; Get prize details
(define-read-only (get-prize-details (hackathon-id uint) (prize-identifier uint))
  (ok (unwrap! (map-get? prizes { hackathon-id: hackathon-id, prize-identifier: prize-identifier })
              ERR-NOT-FOUND))
)

;; Get judge details
(define-read-only (get-judge-details (hackathon-id uint) (judge-principal principal))
  (ok (unwrap! (map-get? judges { hackathon-id: hackathon-id, judge-principal: judge-principal })
              ERR-NOT-FOUND))
)

;; Get score details
(define-read-only (get-score-details (hackathon-id uint) (project-identifier uint) (judge-principal principal))
  (ok (unwrap! (map-get? scores { hackathon-id: hackathon-id, project-identifier: project-identifier, judge-principal: judge-principal })
              ERR-NOT-FOUND))
)

;; Check if participant is in a team
(define-read-only (is-participant-in-team (hackathon-id uint) (participant-principal principal))
  (match (map-get? participants { hackathon-id: hackathon-id, participant-principal: participant-principal })
    participant-record (ok (is-some (get team-identifier participant-record)))
    ERR-NOT-FOUND
  )
)

;; Get current hackathon ID
(define-read-only (get-current-hackathon-id)
  (ok (var-get next-hackathon-id))
)

;; Get platform configuration
(define-read-only (get-platform-config)
  (ok {
    platform-fee-percentage: (var-get platform-fee-percentage),
    fee-recipient: (var-get fee-recipient),
    min-prize-percentage: (var-get min-prize-percentage)
  })
)