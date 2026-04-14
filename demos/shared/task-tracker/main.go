package main

import (
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"os"
	"path/filepath"
	"time"
)

type Task struct {
	ID          int       `json:"id"`
	Title       string    `json:"title"`
	Done        bool      `json:"done"`
	CreatedAt   time.Time `json:"createdAt"`
	CompletedAt time.Time `json:"completedAt,omitempty"`
}

type TaskStore struct {
	NextID int    `json:"nextId"`
	Tasks  []Task `json:"tasks"`
}

func main() {
	if len(os.Args) < 2 {
		printHelp()
		os.Exit(1)
	}

	dataPath := defaultDataPath()
	if envPath := os.Getenv("TASK_TRACKER_DB"); envPath != "" {
		dataPath = envPath
	}

	command := os.Args[1]
	switch command {
	case "add":
		cmdAdd(dataPath, os.Args[2:])
	case "list":
		cmdList(dataPath)
	case "done":
		cmdDone(dataPath, os.Args[2:])
	case "stats":
		cmdStats(dataPath)
	case "help":
		printHelp()
	default:
		fmt.Printf("unknown command: %s\n\n", command)
		printHelp()
		os.Exit(1)
	}
}

func cmdAdd(dataPath string, args []string) {
	fs := flag.NewFlagSet("add", flag.ExitOnError)
	title := fs.String("title", "", "task title")
	_ = fs.Parse(args)

	if *title == "" {
		fmt.Println("error: --title is required")
		os.Exit(1)
	}

	store, err := loadStore(dataPath)
	checkErr(err)

	t := Task{
		ID:        store.NextID,
		Title:     *title,
		Done:      false,
		CreatedAt: time.Now().UTC(),
	}
	store.NextID++
	store.Tasks = append(store.Tasks, t)

	checkErr(saveStore(dataPath, store))
	fmt.Printf("ok: task created (id=%d)\n", t.ID)
}

func cmdList(dataPath string) {
	store, err := loadStore(dataPath)
	checkErr(err)

	if len(store.Tasks) == 0 {
		fmt.Println("no tasks")
		return
	}

	for _, t := range store.Tasks {
		status := "TODO"
		if t.Done {
			status = "DONE"
		}
		fmt.Printf("[%s] #%d %s\n", status, t.ID, t.Title)
	}
}

func cmdDone(dataPath string, args []string) {
	fs := flag.NewFlagSet("done", flag.ExitOnError)
	id := fs.Int("id", 0, "task id")
	_ = fs.Parse(args)

	if *id <= 0 {
		fmt.Println("error: --id must be greater than zero")
		os.Exit(1)
	}

	store, err := loadStore(dataPath)
	checkErr(err)

	found := false
	for i := range store.Tasks {
		if store.Tasks[i].ID == *id {
			if store.Tasks[i].Done {
				fmt.Printf("ok: task already done (id=%d)\n", *id)
				return
			}
			store.Tasks[i].Done = true
			store.Tasks[i].CompletedAt = time.Now().UTC()
			found = true
			break
		}
	}

	if !found {
		fmt.Printf("error: task not found (id=%d)\n", *id)
		os.Exit(1)
	}

	checkErr(saveStore(dataPath, store))
	fmt.Printf("ok: task completed (id=%d)\n", *id)
}

func cmdStats(dataPath string) {
	store, err := loadStore(dataPath)
	checkErr(err)

	total := len(store.Tasks)
	done := 0
	for _, t := range store.Tasks {
		if t.Done {
			done++
		}
	}

	pending := total - done
	fmt.Printf("tasks_total=%d tasks_done=%d tasks_pending=%d\n", total, done, pending)
}

func defaultDataPath() string {
	cwd, err := os.Getwd()
	if err != nil {
		return "tasks.json"
	}
	return filepath.Join(cwd, "tasks.json")
}

func loadStore(path string) (*TaskStore, error) {
	store := &TaskStore{NextID: 1, Tasks: []Task{}}

	if _, err := os.Stat(path); errors.Is(err, os.ErrNotExist) {
		return store, nil
	}

	raw, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}

	if err := json.Unmarshal(raw, store); err != nil {
		return nil, err
	}

	if store.NextID <= 0 {
		maxID := 0
		for _, t := range store.Tasks {
			if t.ID > maxID {
				maxID = t.ID
			}
		}
		store.NextID = maxID + 1
	}

	return store, nil
}

func saveStore(path string, store *TaskStore) error {
	raw, err := json.MarshalIndent(store, "", "  ")
	if err != nil {
		return err
	}
	return os.WriteFile(path, raw, 0644)
}

func checkErr(err error) {
	if err == nil {
		return
	}
	fmt.Printf("error: %v\n", err)
	os.Exit(1)
}

func printHelp() {
	fmt.Println("task-tracker demo")
	fmt.Println("")
	fmt.Println("usage:")
	fmt.Println("  go run . add --title \"text\"")
	fmt.Println("  go run . list")
	fmt.Println("  go run . done --id 1")
	fmt.Println("  go run . stats")
}
