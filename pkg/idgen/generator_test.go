package idgen

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestNewGenerator(t *testing.T) {
	gen := NewGenerator()
	assert.NotNil(t, gen, "Generator should not be nil")
}

func TestGenerateMachineID(t *testing.T) {
	gen := NewGenerator()
	id, err := gen.GenerateMachineID()
	assert.NoError(t, err, "Should not return an error")
	assert.NotEmpty(t, id, "Generated machine ID should not be empty")
}

func TestGenerateDeviceID(t *testing.T) {
	gen := NewGenerator()
	id, err := gen.GenerateDeviceID()
	assert.NoError(t, err, "Should not return an error")
	assert.NotEmpty(t, id, "Generated device ID should not be empty")
}
