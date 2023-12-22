local Translations = {
    success = {
        success_message = "Vellykket",
        fuses_are_blown = "Sikringerne er blevet sprunget",
        door_has_opened = "Døren er åbnet"
    },
    error = {
        cancel_message = "Annulleret",
        safe_too_strong = "Det ser ud til, at safelåsen er for stærk...",
        missing_item = "Du mangler en genstand...",
        bank_already_open = "Banken er allerede åben...",
        minimum_police_required = "Mindst %{police} politi er påkrævet",
        security_lock_active = "Sikkerhedslåsen er aktiv, åbning af døren er i øjeblikket ikke mulig",
        wrong_type = "%{receiver} modtog ikke den rigtige type for argumentet '%{argument}'\nmodtaget type: %{receivedType}\nmodtaget værdi: %{receivedValue}\nforventet type: %{expected}",
        fuses_already_blown = "Sikringerne er allerede sprunget...",
        event_trigger_wrong = "%{event}%{extraInfo} blev udløst, når nogle betingelser ikke blev opfyldt, kilde: %{source}",
        missing_ignition_source = "Du mangler en tændingskilde"
    },
    general = {
        breaking_open_safe = "Bryder sikkerhedsskabet op...",
        connecting_hacking_device = "Forbinder hackingenheden...",
        fleeca_robbery_alert = "Fleeca-bankrøveriforsøg",
        paleto_robbery_alert = "Blain County Savings-bankrøveriforsøg",
        pacific_robbery_alert = "Pacific Standard Bank-røveriforsøg",
        break_safe_open_option_target = "Bryd sikkerhedsskabet op",
        break_safe_open_option_drawtext = "[E] Bryd sikkerhedsskabet op",
        validating_bankcard = "Validerer kort...",
        thermite_detonating_in_seconds = "Thermite går af om %{time} sekund(er)",
        bank_robbery_police_call = "10-90: Bankrøveri"
    }
}
Lang = Lang or Locale:new({
    phrases = Translations,
    warnOnMissing = true
})
