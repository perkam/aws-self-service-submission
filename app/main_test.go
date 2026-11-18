package main

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestRoutes(t *testing.T) {
	tests := []struct {
		name       string
		greeting   string
		method     string
		path       string
		wantStatus int
		wantBody   map[string]string
	}{
		{
			name:       "root returns the greeting",
			greeting:   "Hello from test",
			method:     http.MethodGet,
			path:       "/",
			wantStatus: http.StatusOK,
			wantBody:   map[string]string{"message": "Hello from test"},
		},
		{
			name:       "health is ok when the greeting is set",
			greeting:   "Hello from test",
			method:     http.MethodGet,
			path:       "/health",
			wantStatus: http.StatusOK,
			wantBody:   map[string]string{"status": "ok"},
		},
		{
			name:       "health fails when the greeting is missing",
			greeting:   "",
			method:     http.MethodGet,
			path:       "/health",
			wantStatus: http.StatusServiceUnavailable,
			wantBody:   map[string]string{"status": "error", "error": "GREETING not set"},
		},
		{
			name:       "unknown path is not found",
			greeting:   "Hello from test",
			method:     http.MethodGet,
			path:       "/unknown",
			wantStatus: http.StatusNotFound,
		},
		{
			name:       "other methods are not allowed",
			greeting:   "Hello from test",
			method:     http.MethodPost,
			path:       "/health",
			wantStatus: http.StatusMethodNotAllowed,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			rec := httptest.NewRecorder()
			req := httptest.NewRequest(tt.method, tt.path, nil)

			newMux(tt.greeting).ServeHTTP(rec, req)

			if rec.Code != tt.wantStatus {
				t.Fatalf("status = %d, want %d", rec.Code, tt.wantStatus)
			}
			if tt.wantBody == nil {
				return
			}

			if got := rec.Header().Get("Content-Type"); got != "application/json" {
				t.Errorf("Content-Type = %q, want application/json", got)
			}

			var got map[string]string
			if err := json.Unmarshal(rec.Body.Bytes(), &got); err != nil {
				t.Fatalf("response is not valid JSON: %v", err)
			}
			if len(got) != len(tt.wantBody) {
				t.Fatalf("body = %v, want %v", got, tt.wantBody)
			}
			for key, want := range tt.wantBody {
				if got[key] != want {
					t.Errorf("body[%q] = %q, want %q", key, got[key], want)
				}
			}
		})
	}
}
