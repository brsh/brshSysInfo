## Helper Functions for psSysInfo Module

Function TZ-Change($Day, $DayOfWeek, $Month, $Hour) { 
    $CurrentYear = (Get-Date).Year
    #Using the Switch Statements to convert numeric values into more meaningful information.
    Switch ($Day)
     {
      1 {$STNDDay = "First"}
      2 {$STNDDay = "Second"}
      3 {$STNDDay = "Third"}
      4 {$STNDDay = "Fourth"}
      5 {$STNDDay = "Last"}
     }#End Switch ($TimeZone.StandardDay)      
    Switch ($DayOfWeek)
     {
      0 {$STNDWeek = "Sunday"}
      1 {$STNDWeek = "Monday"}
      2 {$STNDWeek = "Tuesday"}
      3 {$STNDWeek = "Wednesday"}
      4 {$STNDWeek = "Thursday"}
      5 {$STNDWeek = "Friday"}
      6 {$STNDWeek = "Saturday"}
     }#End Switch ($TimeZone.StandardDayOfWeek)      
    Switch ($Month)
     {
      1  {$STNDMonth = "January"}
      2  {$STNDMonth = "February"}
      3  {$STNDMonth = "March"}
      4  {$STNDMonth = "April"}
      5  {$STNDMonth = "May"}
      6  {$STNDMonth = "June"}
      7  {$STNDMonth = "July"}
      8  {$STNDMonth = "August"}
      9  {$STNDMonth = "September"}
      10 {$STNDMonth = "October"}
      11 {$STNDMonth = "November"}
      12 {$STNDMonth = "December"}
     }#End Switch ($TimeZone.StandardMonth)

     [DateTime]$SDate = "$STNDMonth 01, $CurrentYear $Hour`:00:00"

     $i = 0
     While ($i -lt $Day) {
       If ($SDate.DayOfWeek -eq $DayOfWeek) {
         $i++
         If ($i -eq $Day) {
           $SFinalDate = $SDate
         }
         Else {
           $SDate = $SDate.AddDays(1)
         }
       }
       Else {
         $SDate = $SDate.AddDays(1)
       }
     }
     
     #Addressing the DayOfWeek Issue "Last" vs. "Forth" when there are only four of one day in a month
     If ($SFinalDate.Month -ne $Month)
      {
       $SFinalDate = $SFinalDate.AddDays(-7)
      }
      return $SFinalDate
}