define [
  './customer-template'
  './phones-view'
  './addresses-view'
],  (template, PhonesView, AddressesView) ->

  App.module "CarRentAgreement", (Module, App, Backbone, Marionette, $, _) ->

    class Module.Customer extends Marionette.LayoutView
      className:  "layout-view customer"
      template:   template
      phones:     null
      address:    null

      events:
        "click button[name='submit_customer']" :  'onSubmit'

      bindings:
        "[name=first_name]":               observe: "firstName"
        "[name=last_name]":                observe: "lastName"
        "[name=middle_name]":              observe: "middleName"
        "[name=date_of_birth]":
          observe: "dateOfBirth"
          onGet: (value)-> moment.unix(parseInt(value)/1000).format('DD/MM/YYYY')
          onSet: (value)-> moment(value, 'DD/MM/YYYY').unix()*1000
        "[name=license_number]":           observe: "driverLicense"
        "[name=license_expiration_date]":
          observe: "driverLicenseExpirationDate"
          onGet: (value)-> moment.unix(parseInt(value)/1000).format('DD/MM/YYYY')
          onSet: (value)-> moment(value, 'DD/MM/YYYY').unix()*1000
        "[name=license_state]":            observe: "driverLicenseState"
        "[name=email_address]":            observe: "emailAddress"

      regions:
        phones_region:    "#phones-region"
        addresses_region: "#addresses-region"

      initialize:(options)->
        @config = options.config

      onShow:->
        return unless @model

        @stickit()

        @$("[name=date_of_birth]").datetimepicker format:"DD/MM/YYYY"
        @$("[name=license_expiration_date]").datetimepicker format:"DD/MM/YYYY"
        @$("[name=license_state]").select2 data: App.DataHelper.states


        @phones_region.show new PhonesView collection: @model.get 'phones'
        @addresses_region.show new AddressesView collection: @model.get 'addresses'

      onSubmit:->
        @model.save()
          .success (data)->
            debugger
          .error (data)->
            debugger

  App.CarRentAgreement.Customer
