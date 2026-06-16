# graphify-label-reminder.ps1
# Run this after Gemini daily quota resets (usually midnight UTC)
$env:GEMINI_API_KEY = "AQ.Ab8RN6I6dzOvQezcKU1wVyfpbOwWjj1P1_MOMylgCdmRRYdfSQ"
$env:GRAPHIFY_VIZ_NODE_LIMIT = 40000
& "C:\Users\emman\AppData\Roaming\Python\Python314\Scripts\graphify.exe" label .
& "C:\Users\emman\AppData\Roaming\Python\Python314\Scripts\graphify.exe" cluster-only .
