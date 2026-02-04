package work

import "time"

// BurnCPU performs a busy-wait loop that consumes CPU for the specified
// duration in milliseconds. This uses wall-clock time checking rather than
// time.Sleep to ensure actual CPU utilization.
func BurnCPU(milliseconds int) {
	if milliseconds <= 0 {
		return
	}
	deadline := time.Now().Add(time.Duration(milliseconds) * time.Millisecond)
	for time.Now().Before(deadline) {
		// Busy-wait: intentionally empty loop to burn CPU cycles.
		// This simulates real computational work in the microservice.
	}
}
