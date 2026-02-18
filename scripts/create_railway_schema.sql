-- Railway PostgreSQL Schema for Attendance App
-- Run this script in Railway PostgreSQL database

-- Create extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm"; -- For text search

-- ============================================
-- INSTITUTES TABLE
-- ============================================
CREATE TABLE institutes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    code VARCHAR(50) NOT NULL UNIQUE,
    address VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(255),
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Index for institutes
CREATE INDEX idx_institutes_code ON institutes(code);
CREATE INDEX idx_institutes_name ON institutes(name);

-- ============================================
-- BATCHES TABLE
-- ============================================
CREATE TABLE batches (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    institute_id UUID NOT NULL REFERENCES institutes(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    year VARCHAR(50) NOT NULL,
    timing VARCHAR(100) NOT NULL,
    subjects TEXT[] NOT NULL DEFAULT '{}',
    student_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(255),
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for batches
CREATE INDEX idx_batches_institute_id ON batches(institute_id);
CREATE INDEX idx_batches_year ON batches(year);
CREATE INDEX idx_batches_institute_year ON batches(institute_id, year);

-- ============================================
-- STUDENTS TABLE
-- ============================================
CREATE TABLE students (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    institute_id UUID NOT NULL REFERENCES institutes(id) ON DELETE CASCADE,
    batch_id UUID NOT NULL REFERENCES batches(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    roll_number VARCHAR(50) NOT NULL,
    email VARCHAR(255),
    batch_name VARCHAR(255),
    batch_timing VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(institute_id, batch_id, roll_number)
);

-- Indexes for students
CREATE INDEX idx_students_institute_id ON students(institute_id);
CREATE INDEX idx_students_batch_id ON students(batch_id);
CREATE INDEX idx_students_roll_number ON students(roll_number);
CREATE INDEX idx_students_institute_batch ON students(institute_id, batch_id);

-- ============================================
-- ATTENDANCE TABLE
-- ============================================
CREATE TABLE attendance (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    institute_id UUID NOT NULL REFERENCES institutes(id) ON DELETE CASCADE,
    batch_id UUID NOT NULL REFERENCES batches(id) ON DELETE CASCADE,
    batch_name VARCHAR(255),
    roll_number VARCHAR(50) NOT NULL,
    subject VARCHAR(100) NOT NULL,
    date VARCHAR(50) NOT NULL, -- Format: YYYY-MM-DD
    photo_url VARCHAR(500),
    storage_path VARCHAR(500), -- GCS path
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    marked_by VARCHAR(255) NOT NULL,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(institute_id, batch_id, roll_number, subject, date)
);

-- Indexes for attendance
CREATE INDEX idx_attendance_institute_id ON attendance(institute_id);
CREATE INDEX idx_attendance_batch_id ON attendance(batch_id);
CREATE INDEX idx_attendance_roll_number ON attendance(roll_number);
CREATE INDEX idx_attendance_date ON attendance(date);
CREATE INDEX idx_attendance_subject ON attendance(subject);
CREATE INDEX idx_attendance_institute_batch_date ON attendance(institute_id, batch_id, date);
CREATE INDEX idx_attendance_timestamp ON attendance(timestamp);

-- ============================================
-- USERS TABLE
-- ============================================
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) NOT NULL UNIQUE,
    role VARCHAR(50) NOT NULL CHECK (role IN ('admin', 'teacher', 'coder')),
    institute_id UUID REFERENCES institutes(id) ON DELETE SET NULL,
    pin_hash VARCHAR(255), -- Hashed PIN for PIN login
    last_login TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for users
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_institute_id ON users(institute_id);
CREATE INDEX idx_users_role ON users(role);

-- ============================================
-- ERROR LOGS TABLE
-- ============================================
CREATE TABLE error_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    error VARCHAR(1000) NOT NULL,
    stack_trace TEXT,
    context VARCHAR(500),
    app_type VARCHAR(50), -- 'admin' or 'student'
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    resolved BOOLEAN DEFAULT FALSE,
    resolved_at TIMESTAMP
);

-- Indexes for error_logs
CREATE INDEX idx_error_logs_timestamp ON error_logs(timestamp);
CREATE INDEX idx_error_logs_user_id ON error_logs(user_id);
CREATE INDEX idx_error_logs_resolved ON error_logs(resolved);

-- ============================================
-- FUNCTIONS & TRIGGERS
-- ============================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers for updated_at
CREATE TRIGGER update_institutes_updated_at BEFORE UPDATE ON institutes
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_batches_updated_at BEFORE UPDATE ON batches
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_students_updated_at BEFORE UPDATE ON students
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to increment student_count in batches
CREATE OR REPLACE FUNCTION increment_batch_student_count()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE batches
    SET student_count = student_count + 1
    WHERE id = NEW.batch_id;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Function to decrement student_count in batches
CREATE OR REPLACE FUNCTION decrement_batch_student_count()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE batches
    SET student_count = GREATEST(student_count - 1, 0)
    WHERE id = OLD.batch_id;
    RETURN OLD;
END;
$$ language 'plpgsql';

-- Triggers for student_count
CREATE TRIGGER increment_student_count AFTER INSERT ON students
    FOR EACH ROW EXECUTE FUNCTION increment_batch_student_count();

CREATE TRIGGER decrement_student_count AFTER DELETE ON students
    FOR EACH ROW EXECUTE FUNCTION decrement_batch_student_count();

-- ============================================
-- VIEWS (Optional - for easier queries)
-- ============================================

-- View for attendance with student and batch details
CREATE OR REPLACE VIEW attendance_details AS
SELECT 
    a.id,
    a.institute_id,
    a.batch_id,
    a.roll_number,
    a.subject,
    a.date,
    a.photo_url,
    a.timestamp,
    a.marked_by,
    s.name AS student_name,
    s.email AS student_email,
    b.name AS batch_name,
    b.year AS batch_year,
    b.timing AS batch_timing,
    i.name AS institute_name,
    i.code AS institute_code
FROM attendance a
LEFT JOIN students s ON a.roll_number = s.roll_number AND a.batch_id = s.batch_id
LEFT JOIN batches b ON a.batch_id = b.id
LEFT JOIN institutes i ON a.institute_id = i.id;

-- View for batch statistics
CREATE OR REPLACE VIEW batch_statistics AS
SELECT 
    b.id,
    b.institute_id,
    b.name,
    b.year,
    b.timing,
    b.student_count,
    COUNT(DISTINCT a.roll_number) AS students_with_attendance,
    COUNT(a.id) AS total_attendance_records,
    COUNT(DISTINCT a.date) AS days_with_attendance,
    MIN(a.date) AS first_attendance_date,
    MAX(a.date) AS last_attendance_date
FROM batches b
LEFT JOIN attendance a ON b.id = a.batch_id
GROUP BY b.id, b.institute_id, b.name, b.year, b.timing, b.student_count;

-- ============================================
-- GRANT PERMISSIONS (if using separate user)
-- ============================================
-- GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO your_app_user;
-- GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO your_app_user;

-- ============================================
-- COMMENTS
-- ============================================
COMMENT ON TABLE institutes IS 'Educational institutes using the attendance system';
COMMENT ON TABLE batches IS 'Academic batches within institutes';
COMMENT ON TABLE students IS 'Students enrolled in batches';
COMMENT ON TABLE attendance IS 'Daily attendance records with photos';
COMMENT ON TABLE users IS 'System users (admins, teachers, coders)';
COMMENT ON TABLE error_logs IS 'Application error logs for debugging';

-- ============================================
-- SAMPLE DATA (Optional - for testing)
-- ============================================
-- Uncomment to insert sample data for testing

-- INSERT INTO institutes (name, code, address) VALUES
-- ('Test Institute', 'TEST001', '123 Test Street');

-- INSERT INTO batches (institute_id, name, year, timing, subjects) VALUES
-- ((SELECT id FROM institutes WHERE code = 'TEST001'), 'Batch A', '2024', 'Morning', ARRAY['Mathematics', 'Physics']);
