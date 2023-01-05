IDENTIFICATION DIVISION.
PROGRAM-ID. LOCATION-SUMMARY.

ENVIRONMENT DIVISION.
INPUT-OUTPUT SECTION.
FILE-CONTROL.
    SELECT DATABASE-FILE ASSIGN TO "database.db"
        ORGANIZATION IS INDEXED
        ACCESS IS DYNAMIC
        RECORD KEY IS LOCATION.

DATA DIVISION.
FILE SECTION.
FD DATABASE-FILE.
    01 DATABASE-RECORD.
        02 LOCATION PIC X(20).
        02 ENTRY-AMOUNT PIC S9(4)V9(2).

WORKING-STORAGE SECTION.
    01 LOCATION-SUMS.
        02 LOCATION-SUM OCCURS 8 TIMES.
            03 LOCATION PIC X(20).
            03 ENTRY-AMOUNT PIC S9(4)V9(2).
    01 CURRENT-WEEK PIC 9(2).

PROCEDURE DIVISION.
    EXEC SQL CONNECT TO vorpv2
    EXEC SQL SELECT name, money
             INTO :LOCATION, :ENTRY-AMOUNT
             FROM bank_users
    END-EXEC
    PERFORM UNTIL SQL-NOTFOUND
        SORT LOCATION-SUMS ON ASCENDING KEY LOCATION
        ADD ENTRY-AMOUNT TO LOCATION-SUM(CURRENT-WEEK) OF LOCATION-SUMS
        EXEC SQL FETCH NEXT FROM vorpv2
    END-PERFORM
    EXEC SQL DISCONNECT vorpv2

    * Predict next 8 weeks based on data
    PERFORM PREDICT-NEXT-EIGHT-WEEKS

    STOP RUN.

PREDICT-NEXT-EIGHT-WEEKS.
    * Calculate average for each location
    MOVE ZERO TO LOCATION-SUM(8) OF LOCATION-SUMS
    PERFORM VARYING WEEK FROM 1 BY 1 UNTIL WEEK > 8
        ADD LOCATION-SUM(WEEK) OF LOCATION-SUMS TO LOCATION-SUM(8) OF LOCATION-SUMS
    END-PERFORM
    DIVIDE LOCATION-SUM(8) OF LOCATION-SUMS BY 8 GIVING LOCATION-SUM(9) OF LOCATION-SUMS

    * Predict next 8 weeks based on averages
    PERFORM VARYING WEEK FROM 1 BY 1 UNTIL WEEK > 8
        MOVE LOCATION-SUM(9) OF LOCATION-SUMS TO LOCATION-SUM(WEEK) OF LOCATION-SUMS
    END-PERFORM