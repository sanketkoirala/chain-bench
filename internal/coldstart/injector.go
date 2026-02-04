package coldstart

import (
	"math"
	"math/rand"
	"sync"
	"time"
)

// Injector provides probabilistic cold-start delay injection using a
// log-normal distribution to model realistic Kubernetes pod cold-start times.
type Injector struct {
	probability float64
	mu          float64
	sigma       float64
	rng         *rand.Rand
	mu_lock     sync.Mutex
}

// NewInjector creates a cold-start injector.
// medianMS is the median cold-start delay in milliseconds.
// sigma is the log-normal sigma parameter controlling variance.
// probability is the chance (0.0-1.0) of injecting a cold-start per request.
func NewInjector(probability, medianMS, sigma float64) *Injector {
	return &Injector{
		probability: probability,
		mu:          math.Log(medianMS),
		sigma:       sigma,
		rng:         rand.New(rand.NewSource(time.Now().UnixNano())),
	}
}

// MaybeDelay checks whether a cold-start should be injected and, if so,
// sleeps for a duration drawn from the log-normal distribution.
// Returns whether a cold-start was injected and the delay in milliseconds.
func (inj *Injector) MaybeDelay() (injected bool, delayMS float64) {
	inj.mu_lock.Lock()
	roll := inj.rng.Float64()
	var delay float64
	if roll < inj.probability {
		normalSample := inj.rng.NormFloat64()
		delay = math.Exp(inj.mu + inj.sigma*normalSample)
	}
	inj.mu_lock.Unlock()

	if roll < inj.probability {
		time.Sleep(time.Duration(delay) * time.Millisecond)
		return true, delay
	}
	return false, 0
}
