@{
    Severity = @('Error', 'Warning')

    ExcludeRules = @(
        'PSAvoidUsingWriteHost',
        'PSUseApprovedVerbs'
    )

    Rules = @{
        PSUseDeclaredVarsMoreThanAssignments = @{
            Enable = $true
        }

        PSUseSingularNouns = @{
            Enable = $true
        }

        PSAvoidUsingInvokeExpression = @{
            Enable = $true
        }

        PSAvoidUsingCmdletAliases = @{
            Enable = $true
            Aliases = @('gci', 'ls', 'foreach', '%', 'select', 'where', 'write')
        }

        PSAvoidUsingEmptyCatchBlock = @{
            Enable = $true
        }

        PSAvoidUsingWriteHost = @{
            Enable = $false
        }

        PSAvoidUsingPositionalParameters = @{
            Enable = $true
        }

        PSProvideCommentHelp = @{
            Enable = $true
            ExportedOnly = $false
            BlockComment = $true
            VSCodeSnippetCompatible = $true
            Placement = 'BeforeOrAfter'
        }

        PSReviewUnusedParameter = @{
            Enable = $true
        }

        PSAvoidUsingComputerNameHardcoded = @{
            Enable = $true
        }

        PSAvoidUsingUsernameAndPasswordParams = @{
            Enable = $true
        }

        PSAvoidGlobalFunctions = @{
            Enable = $true
        }

        PSAvoidUsingAliases = @{
            Enable = $true
        }

        PSUseCorrectCasing = @{
            Enable = $true
        }

        PSUseShouldProcessForStateChangingFunctions = @{
            Enable = $true
        }

        PSAvoidUsingDeprecatedManifestFields = @{
            Enable = $true
        }

        PSPlaceOpenBrace = @{
            Enable = $true
            OnSameLine = $true
            NewLineAfter = $true
        }

        PSPlaceCloseBrace = @{
            Enable = $true
            NewLineAfter = $false
        }

        PSUseConsistentIndentation = @{
            Enable = $true
            IndentationSize = 4
            PipelineIndentation = 'IncreaseIndentationForFirstPipeline'
        }

        PSUseConsistentWhitespace = @{
            Enable = $true
            CheckOpenBrace = $true
            CheckOpenParen = $true
            CheckOperator = $true
            CheckSeparator = $true
        }
    }
}
