# Blockathon

## Overview

**Blockathon** is a decentralized hackathon management smart contract built on the Stacks blockchain. It enables transparent event creation, participant registration, team formation, project submissions, judging, and prize distribution. The contract supports both **STX** and **SIP-010 tokens** as funding options, ensuring flexibility for organizers and sponsors.

## Key Features

* **Hackathon Creation:** Organizers can set up hackathons with parameters such as timelines, prize pools, judging methods, and event details.
* **Participant Management:** Tracks registration, approval, and participation of users in various hackathon events.
* **Team System:** Supports the creation and management of teams with descriptions, members, and repositories.
* **Project Submissions:** Allows teams to submit project data, including metadata, repositories, demo links, and track details.
* **Judging Mechanism:** Supports multiple judging modes—**panel**, **community**, or **hybrid**—with detailed scoring records and weighted evaluations.
* **Prize Distribution:** Automates the funding of prize pools in STX or SIP-010 tokens, calculates platform fees, and supports prize claiming by winners.
* **Sponsor Integration:** Enables sponsors to contribute funds or custom prizes with tiered recognition.
* **Activity Logging:** Every important event (registration, team creation, submission, etc.) is recorded in the activity log for full transparency.

## Core Contract Components

1. **Data Maps**

   * `hackathons`: Stores all hackathon event metadata.
   * `participants`: Manages participant profiles and registration data.
   * `teams`: Tracks team information and membership.
   * `projects`: Handles project submissions and evaluation statuses.
   * `judges`: Manages judge assignments, expertise, and scoring data.
   * `scores`: Stores judges’ scores, feedback, and weighted results.
   * `prizes`: Defines prize structures and claim information.
   * `sponsors`: Records sponsor details and contributions.
   * `event-activity`: Logs on-chain activity for auditability.

2. **Core Functions**

   * `create-hackathon`: Initializes a new hackathon event with all key configurations.
   * `fund-prize-pool-stx`: Allows organizers to fund the prize pool using STX, applying platform fees.
   * `fund-prize-pool-ft`: Enables funding using SIP-010 compliant fungible tokens.
   * `log-event-activity`: Privately records all relevant event actions on-chain.

3. **Validation and Configuration**

   * Ensures valid timelines, participant limits, and prize pool ratios.
   * Configurable platform fees and minimum prize allocation percentages.

## Token Compatibility

* **STX (Native):** Direct funding and transfers within the contract.
* **SIP-010 Tokens:** Supports fungible token integration through a standard trait interface.

## Security and Governance

* **Authorization Checks:** Organizer-only functions for event creation and prize funding.
* **Platform Fee Logic:** Enforces consistent fee deductions and transfers to the designated recipient.
* **Immutable Transparency:** All participant, project, and prize actions are traceable via on-chain logs.

## Summary

**Blockathon** provides a complete on-chain infrastructure for managing decentralized hackathons. By integrating event logistics, team collaboration, judging, and prize management within a single transparent system, it promotes fairness, verifiability, and accessibility in competitive innovation ecosystems.
