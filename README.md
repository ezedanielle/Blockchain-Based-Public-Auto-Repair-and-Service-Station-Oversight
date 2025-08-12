# Blockchain-Based Public Auto Repair and Service Station Oversight

A comprehensive smart contract system for managing and overseeing auto repair and service stations, ensuring compliance, transparency, and consumer protection.

## System Overview

This system consists of five interconnected smart contracts that manage different aspects of auto repair oversight:

### 1. Auto Repair Licensing Contract (`auto-repair-licensing.clar`)
- Issues and manages repair facility permits
- Tracks technician certifications and qualifications
- Manages license renewals and suspensions
- Maintains registry of authorized repair shops

### 2. Environmental Compliance Monitoring Contract (`environmental-compliance.clar`)
- Monitors proper disposal of motor oil, antifreeze, and automotive fluids
- Tracks waste disposal records and compliance reports
- Issues environmental violations and penalties
- Manages hazardous material handling certifications

### 3. Emissions Testing Coordination Contract (`emissions-testing.clar`)
- Manages vehicle emissions testing programs
- Coordinates testing schedules and certifications
- Tracks testing equipment calibration
- Issues emissions compliance certificates

### 4. Parts Warranty Tracking Contract (`parts-warranty.clar`)
- Monitors warranty claims and coverage periods
- Ensures proper installation of replacement parts
- Tracks part authenticity and supplier information
- Manages warranty dispute resolution

### 5. Consumer Protection Compliance Contract (`consumer-protection.clar`)
- Ensures fair pricing and transparent billing
- Prevents fraudulent repair practices
- Manages customer complaints and resolutions
- Tracks repair shop ratings and reviews

## Key Features

- **Transparency**: All transactions and compliance records are stored on-chain
- **Accountability**: Immutable audit trail for all oversight activities
- **Automation**: Smart contract logic automates compliance checking and reporting
- **Public Access**: Citizens can verify shop credentials and compliance status
- **Regulatory Compliance**: Built-in enforcement mechanisms for violations

## Data Structures

### Shop Registration
- Shop ID, name, address, contact information
- License status, expiration dates
- Technician certifications
- Compliance history

### Environmental Records
- Waste disposal logs
- Fluid handling records
- Environmental violation history
- Certification status

### Emissions Data
- Testing schedules and results
- Equipment calibration records
- Compliance certificates
- Violation tracking

### Warranty Information
- Parts installation records
- Warranty claim history
- Supplier verification
- Customer satisfaction data

### Consumer Protection
- Pricing transparency records
- Complaint resolution history
- Shop ratings and reviews
- Fraud prevention measures

## Getting Started

1. Install dependencies: \`npm install\`
2. Run tests: \`npm test\`
3. Deploy contracts using Clarinet
4. Initialize system with regulatory authority

## Testing

The system includes comprehensive tests covering:
- Contract deployment and initialization
- License issuance and management
- Compliance monitoring and reporting
- Warranty tracking and claims
- Consumer protection mechanisms
- Error handling and edge cases

## Compliance Framework

The system enforces compliance through:
- Automated violation detection
- Penalty assessment and collection
- License suspension mechanisms
- Public transparency requirements
- Regular audit and reporting cycles
  
