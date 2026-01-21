# HomelyHope - Complete Project Documentation

## Project Overview

HomelyHope is a comprehensive mobile application designed to connect homeless individuals with organizations, merchants, and donors. The platform facilitates job opportunities, donations, and support services for people experiencing homelessness. The app serves four main user roles: Organizations, Merchants, Donors, and Homeless individuals, each with specific features and capabilities to help create a supportive community network.

---

## Authentication & Onboarding Screens

### 1. Splash Screen
**Title:** Application Launch Screen  
**Description:**  
The splash screen is the first screen users see when opening the app. It displays the HomelyHope logo and branding for 3 seconds while the app checks if the user is already logged in. If logged in, it automatically redirects to the appropriate dashboard based on the user's role. If not logged in, it navigates to the login screen.

### 2. Login Screen
**Title:** User Login  
**Description:**  
The login screen allows existing users to sign in to their account. Users enter their email address and password to access the application. The screen includes a "Forgot Password" option for users who cannot remember their credentials. After successful login, users are redirected to their role-specific dashboard. Organizations must be verified before accessing their dashboard.

### 3. Role Selection Screen
**Title:** Choose Your Role  
**Description:**  
Before signing up, new users must select their role on this screen. The app offers four role options: Organization, Merchant, Donor, or Homeless. Each role has different sign-up requirements and features. Homeless individuals cannot sign up directly - they must be added by an organization. After selecting a role, users are taken to the corresponding sign-up form.

### 4. Forgot Password Screen
**Title:** Reset Password  
**Description:**  
This screen helps users recover their account by resetting their password. Users enter their registered email address, and the system sends a password reset link or code to their email. This allows users to create a new password and regain access to their account.

---

## Sign-Up Screens

### 5. Organization Sign-Up Screen
**Title:** Register as Organization  
**Description:**  
Organizations that provide support services to homeless individuals can register through this form. The sign-up process requires organization details such as organization name, email, phone number, address, registration documents, and verification information. After registration, organizations must wait for admin verification before they can fully access the platform. Organizations can also edit their registration details later.

### 6. Merchant Sign-Up Screen
**Title:** Register as Merchant  
**Description:**  
Businesses and merchants who want to post job opportunities can register here. The form collects business information including business name, owner details, contact information, business address, and business type. Once registered, merchants can immediately start posting jobs and managing their business profile.

### 7. Donor Sign-Up Screen
**Title:** Register as Donor  
**Description:**  
Individuals who want to make donations to support homeless people can create an account through this screen. The registration form asks for personal information like full name, email, phone number, address, and preferred donation type (money, food, clothes, services, etc.). After registration, donors can browse homeless profiles and make donations immediately.

**Note:** Homeless individuals do not have a sign-up screen. They are added to the system by organizations that support them. Organizations create profiles for homeless individuals with their personal information, skills, and needs.

---

## Organization Role Screens

After logging in as an Organization, users have access to the following screens:

### 8. Organization Dashboard
**Title:** Organization Overview Dashboard  
**Description:**  
The dashboard provides a comprehensive overview of the organization's activities. It displays key statistics including the number of homeless people supported, active job postings, total donations received, and donation charts showing monthly trends. The dashboard includes quick action buttons to add new homeless individuals and view reports. Organizations can see their key performance indicators (KPIs) and recent activity summaries at a glance.

### 9. Homeless People Table
**Title:** Manage Homeless Individuals  
**Description:**  
This screen displays a searchable and filterable list of all homeless individuals registered under the organization. Organizations can search by name, filter by status, sort by various criteria, and view detailed information. Each homeless person's card shows their profile picture, name, age, skills, and current status. Organizations can add new homeless individuals, view detailed profiles, edit information, and manage their records from this screen.

### 10. Add Homeless Person Screen
**Title:** Register New Homeless Individual  
**Description:**  
Organizations use this form to add new homeless individuals to the system. The form collects personal information including full name, username, email, phone number, age, gender, profile picture, skills, experience, location, address, and bio. This information helps match homeless individuals with suitable job opportunities and allows donors to understand their needs better.

### 11. View Homeless Detail Screen
**Title:** Homeless Individual Profile Details  
**Description:**  
This detailed view screen shows complete information about a specific homeless individual. Organizations can see all personal details, skills, experience, location, and profile information. The screen allows organizations to edit the profile, view donation history, see job applications, and manage the individual's account. It provides a comprehensive view of each person's journey and current status.

### 12. Jobs Page (Organization View)
**Title:** Browse Available Jobs  
**Description:**  
Organizations can view all available job postings from merchants on this screen. The page displays jobs in an expandable card format with search and filter capabilities. Organizations can search jobs by title, filter by category or status, and sort by various criteria. Each job card shows the job title, description, salary range, location, posted by information, and application status. This helps organizations match homeless individuals with suitable job opportunities.

### 13. Donation History Screen (Organization)
**Title:** Organization Donation Records  
**Description:**  
This screen shows all donations received by the organization for their homeless individuals. Organizations can see a summary of total donations, completed donations, pending donations, and view detailed donation records. Each donation entry displays donor information, amount, donation type, status, date, and transaction details. This helps organizations track financial support and manage donation records effectively.

### 14. My Profile Screen (Organization)
**Title:** Organization Profile Management  
**Description:**  
Organizations can view and edit their profile information on this screen. It displays organization details including name, email, phone, address, verification status, and registration information. Organizations can update their contact information, change passwords, upload documents, and manage their account settings. The screen also shows account status and verification information.

### 15. Chat List Screen (Organization)
**Title:** Messages and Conversations  
**Description:**  
Organizations can communicate with homeless individuals, donors, and other users through this messaging interface. The screen displays a list of all active conversations, showing the other person's name, last message preview, and timestamp. Organizations can start new chats, view message history, and send messages to coordinate support services and stay connected with their community.

### 16. Create New Chat Screen
**Title:** Start a New Conversation  
**Description:**  
This screen allows organizations to initiate new conversations with users. Organizations can search and select from a list of homeless individuals registered under their organization to start a chat. The screen displays user profiles with names, photos, and basic information to help organizations identify the person they want to contact.

---

## Merchant Role Screens

After logging in as a Merchant, users have access to the following screens:

### 17. Merchant Dashboard
**Title:** Business Overview Dashboard  
**Description:**  
The merchant dashboard provides an overview of business activities including active job postings, total applicants, recent job applications, and business statistics. Merchants can quickly see how many jobs they have posted, how many people have applied, and view recent activity. The dashboard includes quick action buttons to post new jobs and manage existing postings.

### 18. Jobs Management Screen (Merchant)
**Title:** Manage Job Postings  
**Description:**  
Merchants can create, view, edit, and manage all their job postings on this screen. The page displays jobs in an attractive card format with search and filter options. Merchants can search jobs by title (with highlighted matching text), filter by status or category, and sort by various criteria. Each job card shows job details, salary range, location, status, and number of applicants. Merchants can add new jobs, edit existing ones, view applicants, and manage job postings from this screen.

### 19. Add/Edit Job Screen
**Title:** Create or Update Job Posting  
**Description:**  
Merchants use this form to create new job postings or edit existing ones. The form collects job information including job title, description, category, salary range (minimum and maximum), location with address, and job status. Merchants can save jobs as drafts or publish them immediately. The same screen is used for editing existing jobs, with all fields pre-filled with current information.

### 20. Applicants Table Screen (Merchant)
**Title:** View Job Applicants  
**Description:**  
Merchants can view all homeless individuals who have applied or are interested in their job postings through this screen. The table displays applicant profiles with search and filter capabilities. Merchants can see applicant details, skills, experience, and contact information. This helps merchants review candidates and make hiring decisions.

### 21. My Profile Screen (Merchant)
**Title:** Business Profile Management  
**Description:**  
Merchants can view and update their business profile information on this screen. It displays business details including business name, owner information, contact details, business address, and business type. Merchants can edit their information, change passwords, update business documents, and manage account settings.

### 22. Chat List Screen (Merchant)
**Title:** Business Communications  
**Description:**  
Merchants can communicate with job applicants, organizations, and other users through this messaging interface. The screen shows all active conversations with message previews and timestamps. Merchants can start new chats, respond to messages, and coordinate with applicants and organizations regarding job opportunities.

---

## Donor Role Screens

After logging in as a Donor, users have access to the following screens:

### 23. Donor Dashboard
**Title:** Donor Overview Dashboard  
**Description:**  
The donor dashboard provides a comprehensive view of donation activities and impact. It displays statistics including total donations made, total amount donated, recent donations, and donation trends shown in interactive charts. Donors can see their contribution history, view donation summaries, and track their impact on helping homeless individuals. The dashboard includes quick action buttons to make new donations and view donation history.

### 24. Homeless People Table (Donor View)
**Title:** Browse People in Need  
**Description:**  
Donors can browse through a searchable and filterable list of homeless individuals who need support. The table displays profiles with photos, names, ages, skills, and brief descriptions. Donors can search by name, filter by various criteria, and sort the list. Each profile card shows key information to help donors understand the person's situation and needs. Donors can click on a profile to view details and make a donation.

### 25. Donate to Homeless Person Screen
**Title:** Make a Donation  
**Description:**  
Donors use this form to make donations to specific homeless individuals. The form allows donors to select donation type (money, food, clothes, services, or other), enter the donation amount, choose currency (INR, USD, EUR), add a description, select payment method (Cash, Bank Transfer, UPI, Credit Card, etc.), enter transaction ID, and add optional notes. After submission, donors receive confirmation and the donation is recorded in the system.

### 26. Organization Table Screen
**Title:** Browse Support Organizations  
**Description:**  
Donors can view all registered organizations that support homeless individuals on this screen. The table displays organizations with search, filter, and sort capabilities. Each organization card shows the organization name, type, status, contact information, and verification status. Donors can expand cards to see more details and learn about different organizations working to help homeless people.

### 27. Donation History Screen (Donor)
**Title:** My Donation Records  
**Description:**  
Donors can view all their past donations on this screen. It displays a summary showing total amount donated, number of donations, completed donations, and pending donations. Each donation entry shows recipient information, donation type, amount, currency, status, date, payment method, transaction ID, and receipt number. Donors can track their giving history and download receipts for their records.

### 28. My Profile Screen (Donor)
**Title:** Donor Profile Management  
**Description:**  
Donors can view and edit their personal profile information on this screen. It displays personal details including full name, email, phone number, address, preferred donation type, and account verification status. Donors can update their contact information, change passwords, and manage account settings. The screen also shows account activity and verification status.

---

## Homeless Role Screens

Homeless individuals are added to the system by organizations and can access the following screens after login:

### 29. Homeless Dashboard
**Title:** Personal Overview Dashboard  
**Description:**  
The homeless dashboard provides a personalized overview of opportunities and support received. It displays quick statistics including total available jobs, applied jobs, matching jobs based on skills, total donations received, recent donations count, and active job postings. The dashboard shows recent job opportunities, recent donations received from donors, and insights about job categories and statuses. This helps homeless individuals understand their current situation and available opportunities.

### 30. Jobs Page (Homeless View)
**Title:** Browse Job Opportunities  
**Description:**  
Homeless individuals can view all available job postings from merchants on this screen. The page displays jobs in an attractive, expandable card format with search and filter capabilities. Users can search jobs by title, filter by category or status, and sort by various criteria. Each job card shows job title, description, category, salary range, location, posted by information (merchant name), and time posted. Homeless individuals can view job details and apply for positions that match their skills.

### 31. Donation History Screen (Homeless)
**Title:** My Received Donations  
**Description:**  
Homeless individuals can view all donations they have received from donors on this screen. It displays a summary card showing total amount received (for completed donations), number of completed donations, pending donations count, and total donations count. Each donation entry shows donor name and email, donation title, amount with currency, donation type, status, description, organization name, payment method, transaction ID, receipt number (if available), and time received. This helps individuals track the support they have received.

### 32. My Profile Screen (Homeless)
**Title:** Personal Profile Management  
**Description:**  
Homeless individuals can view and edit their personal profile information on this screen. It displays personal details including full name, username, email, phone number, age, gender, profile picture, skills, experience, location, address, and bio. Users can update their information, change profile pictures, update skills and experience, and manage their account settings. This profile helps match them with suitable job opportunities and allows donors to understand their needs.

### 33. Chat List Screen (Homeless)
**Title:** My Messages  
**Description:**  
Homeless individuals can communicate with organizations, donors, and other users through this messaging interface. The screen displays all active conversations showing the other person's name, last message preview, and timestamp. Users can start new chats with organizations, view message history, and send messages to stay connected with their support network and coordinate services.

---

## Common Features Across All Roles

### 34. Chat Page
**Title:** Individual Conversation  
**Description:**  
This screen displays an individual chat conversation between two users. It shows the message history in a chat bubble format, with sent messages on one side and received messages on the other. Users can type and send new messages, see message timestamps, and view message delivery status. The chat supports real-time messaging and helps users communicate effectively.

### 35. Dynamic Drawer Menu
**Title:** Navigation Menu  
**Description:**  
All authenticated users have access to a side drawer menu that provides quick navigation to different screens. The menu items vary based on the user's role and include options like Dashboard, Profile, Jobs, Donations, Chat, and Logout. The drawer provides easy access to all major features of the application.

---

## Key Features Summary

- **Role-Based Access:** Each user role has specific screens and features tailored to their needs
- **Real-Time Communication:** Chat functionality allows all users to communicate with each other
- **Job Management:** Merchants can post jobs, and homeless individuals can browse and apply
- **Donation System:** Donors can make donations, and recipients can track received donations
- **Profile Management:** All users can manage their profiles and account information
- **Search & Filter:** Most list screens include search and filter capabilities for easy navigation
- **Dashboard Analytics:** Role-specific dashboards provide insights and statistics
- **Verification System:** Organizations require admin verification before full access
- **Responsive Design:** Modern UI with glassmorphism effects and smooth animations

---

## User Flow Summary

1. **New User:** Splash Screen → Login → Role Selection → Sign Up → Login → Dashboard
2. **Existing User:** Splash Screen → Dashboard (based on role)
3. **Organization Flow:** Dashboard → Add Homeless → Manage Jobs → View Donations → Chat
4. **Merchant Flow:** Dashboard → Post Jobs → View Applicants → Manage Profile → Chat
5. **Donor Flow:** Dashboard → Browse Homeless → Make Donation → View History → Chat
6. **Homeless Flow:** Dashboard → Browse Jobs → View Donations → Update Profile → Chat

---

*This documentation provides a comprehensive overview of all screens and features in the HomelyHope application. Each screen is designed to serve specific purposes within the overall mission of connecting and supporting homeless individuals with opportunities and resources.*

