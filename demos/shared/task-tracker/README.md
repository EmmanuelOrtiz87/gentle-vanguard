# Task Tracker Demo Project

Simple project used in demo simulations to show stack workflow from request to closure.

## Start Here

1. Use this project only for stack demos.
2. Keep scope small and deterministic.
3. Follow the cookbook in `demos/07-mixed-cookbook-real-request/DEMO.md`.

## Functional Goal

A tiny CLI to add, list, complete, and summarize tasks in a local JSON file.

## Why This Project

1. Fast to understand in less than 5 minutes.
2. Small enough to focus on stack capabilities instead of app complexity.
3. Good fit to demonstrate AI-assisted iteration, reviews, audits, and closure.

## Run

1. `go run . add --title "prepare sprint demo"`
2. `go run . list`
3. `go run . done --id 1`
4. `go run . stats`

## Scope

1. No external services.
2. No database server.
3. Single local execution flow.

## Files to Know

1. `main.go` - CLI commands and JSON persistence.
2. `go.mod` - module definition.
3. `tasks.json` - generated runtime file.
