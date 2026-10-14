Namespace Demo
    Public Module Runner
        Public Sub Run()
            ' FakeCall() should not appear in invocation results.
            Dim label As String = "OtherFake()"
            System.Console.WriteLine(label)
            Helper()
        End Sub
        Private Sub Helper()
        End Sub
    End Module
End Namespace
