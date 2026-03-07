## College Classroom & Seminar Hall Booking System

This project is a starter implementation for a college room booking app.

- Frontend: Flutter
- Backend: Node.js + Express
- Database: MongoDB

It supports:

- Complete CS department timetable storage
- Classroom/seminar hall details (room number, capacity, projector)
- Batch assignment in timetable entries
- Class representative details (name + admission number)
- Faculty details (name + faculty ID) per subject entry
- Availability check based on timetable + existing bookings
- Booking creation with conflict prevention
- Role-based login for faculty, representative, and admin

---

## Project Structure

```
backend/
	src/
		config/
		models/
		routes/
		seed/
		utils/
		app.js
		server.js
flutter_app/
	lib/
		core/api/
		features/booking/
```

---

## Backend Setup

1. Open terminal in `backend` folder
2. Install dependencies:

	 ```bash
	 npm install
	 ```

3. Create `.env` from `.env.example`

	 ```env
	 PORT=5000
	 MONGO_URI=mongodb://127.0.0.1:27017/college_room_booking
	 JWT_SECRET=replace-with-strong-secret
	 ```

4. Seed sample CS data:

	 ```bash
	 npm run seed
	 ```

5. Start API:

	 ```bash
	 npm run dev
	 ```

Base URL: `http://localhost:5000`

---

## Core API Endpoints

### Health

- `GET /health`

### Classrooms

- `GET /api/classrooms`
- `POST /api/classrooms`
- `POST /api/classrooms/bulk`

Sample classroom payload:

```json
{
	"roomNumber": "C-301",
	"name": "Advanced Computing Lab",
	"type": "classroom",
	"capacity": 72,
	"hasProjector": true
}
```

Bulk classroom upload payload:

```json
{
	"classrooms": [
		{
			"roomNumber": "C-101",
			"name": "CS Classroom 1",
			"type": "classroom",
			"capacity": 60,
			"hasProjector": true
		},
		{
			"roomNumber": "SH-1",
			"name": "CS Seminar Hall",
			"type": "seminar_hall",
			"capacity": 180,
			"hasProjector": true
		}
	]
}
```

### Timetable

- `GET /api/timetable?dayOfWeek=1&batch=CS-2A&facultyId=FAC-CS-101`
- `POST /api/timetable`
- `POST /api/timetable/bulk`

Sample timetable payload:

```json
{
	"classroom": "<classroom_id>",
	"dayOfWeek": 1,
	"startTime": "09:00",
	"endTime": "10:00",
	"subject": "Data Structures",
	"faculty": {
		"name": "Dr. Rao",
		"facultyId": "FAC-CS-101"
	},
	"batch": "CS-2A",
	"classRepresentative": {
		"name": "Arjun Menon",
		"admissionNumber": "CS22A001"
	},
	"batchesPresent": ["CS-2A"]
}
```

Bulk timetable upload payload:

```json
{
	"entries": [
		{
			"classroom": "<classroom_id>",
			"dayOfWeek": 1,
			"startTime": "09:00",
			"endTime": "10:00",
			"subject": "Data Structures",
			"faculty": {
				"name": "Dr. Rao",
				"facultyId": "FAC-CS-101"
			},
			"batch": "CS-2A",
			"classRepresentative": {
				"name": "Arjun Menon",
				"admissionNumber": "CS22A001"
			},
			"batchesPresent": ["CS-2A"]
		}
	]
}
```

### Bookings

- `GET /api/bookings`
- `GET /api/bookings/availability?date=2026-03-03&startTime=10:00&endTime=11:00&minCapacity=60&projector=true&type=classroom`
- `POST /api/bookings`
- `PATCH /api/bookings/:id/status`

Sample booking payload:

```json
{
	"room": "<classroom_id>",
	"date": "2026-03-03",
	"startTime": "10:00",
	"endTime": "11:00",
	"requestedBy": "Student Coordinator",
	"purpose": "Placement Talk",
	"batch": "CS-4A"
}
```

### Authentication

- `GET /api/auth/roles`
- `POST /api/auth/login`

Login rules:

- Faculty login ID = faculty ID number
- Representative login ID = admission number
- Admin login ID = admin ID
- Default password = `LBSCEK`

Sample login payload:

```json
{
	"role": "faculty",
	"loginId": "FAC-CS-101",
	"password": "LBSCEK"
}
```

Sample success response:

```json
{
	"token": "<jwt_token>",
	"user": {
		"id": "<user_id>",
		"role": "faculty",
		"loginId": "FAC-CS-101",
		"name": "Dr. Rao"
	}
}
```

Seeded admin account:

- role: `admin`
- loginId: `ADMIN001`
- password: `LBSCEK`

---

## Flutter Integration

Use the files already created under `flutter_app/lib`:

- `core/api/api_client.dart`
- `main.dart`
- `features/auth/presentation/role_selection_page.dart`
- `features/auth/presentation/role_login_page.dart`
- `features/auth/presentation/dashboard_page.dart`
- `features/auth/services/auth_api_service.dart`
- `features/booking/services/booking_api_service.dart`
- `features/booking/models/*`

Example usage:

```dart
final apiClient = ApiClient(baseUrl: 'http://10.0.2.2:5000');
final bookingService = BookingApiService(apiClient);

final availableRooms = await bookingService.checkAvailability(
	date: '2026-03-03',
	startTime: '10:00',
	endTime: '11:00',
	minCapacity: 60,
	projector: true,
	type: 'classroom',
);
```

For Android emulator, `10.0.2.2` maps to local machine `localhost`.

Authentication UI behavior:

1. App opens on role selection page with Faculty, Representative, Admin.
2. Selecting a role opens the corresponding login page.
3. Login verifies role + loginId + password using backend API.
4. On success, app redirects to role-specific dashboard.

---

## Suggested Next Steps

- Add approval workflow UI in Flutter
- Add calendar view for timetable and bookings
- Add validation + unit tests for booking and authentication logic

