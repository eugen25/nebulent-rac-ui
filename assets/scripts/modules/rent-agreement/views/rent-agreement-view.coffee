define [
    './rent-agreement-template'
    './customer-view'
    './../models/customer-model'
    './../models/deposit-model'
    './vehicle-view'
    './deposit-view'
    './../models/vehicle-model'
    './../models/organization-model'
],  (template, CustomerView, CustomerModel, DepositModel,  VehicleView, DepositView
     VehicleModel, OrganizationModel) ->

  App.module "CarRentAgreement", (Module, App, Backbone, Marionette, $, _) ->

    class Module.RentAgreement extends Marionette.LayoutView
      className:        "layout-view rent-agreement"
      template:         template

      currentCustomer:  null
      currentVehicle:   null
      currentDeposit:   null

      dataCollection:
        organization: false
        customers:    false
        deposits:     false

      ui:
        vehicleSearch: 'input[name="vehicle_search"]'
        customerSearch: 'input[name="customer_search"]'
        depositSearch: 'input[name="deposit_search"]'


      events:
        'change input:radio[name="customerChoiceRadios"]':      "customerChoiceChange"
        'change input:radio[name="depositChoiceRadios"]':       "depositChoiceChange"
        'change @ui.vehicleSearch':                             "onVehicleSearch"
        'change @ui.customerSearch':                            "onCustomerSearch"
        'change @ui.depositSearch':                             "onDepositSearch"
        'click #submit-rent-agreement':                         "onSubmit"
        'loaded':                                               "initViewElements"

      bindings:
        'input[name="daily_rate"]'         : observe: 'dailyRate'
        'input[name="days"]'               : observe: 'days'
        'input[name="subtotal"]'           : observe: 'subTotal'
        'input[name="total"]'              : observe: 'total'
        'input[name="currentMileage"]'     : observe: 'startMileage'
        'input[name="fuelLevel"]'          : observe: 'fuelLevel'
        'input[name="totalTax"]'           : observe: 'totalTax'
        'input[name="discount_rate"]'      : observe: 'discountRate'
#        'input[name="customer_search"]'    : observe: 'customer'
#        'input[name="vehicle_search"]'     : observe: 'vehicle'
#        'input[name="deposit_search"]'     : observe: 'deposit'

      regions:
        customer_region:  "#customer-region"
        vehicle_region:   "#vehicle-region"
        deposit_region:   "#deposit-region"

      initialize:->
        window.model = @model
        @organization ?= new OrganizationModel()
        Module.organization = @organization
        window.organization = @organization
        @listenTo @model, 'change:customer',  @onCustomerChange
        @listenTo @model, 'change:vehicle',   @onVehicleChange
        @listenTo @model, 'change:deposit',   @onDepositChange
        @listenTo @model, 'change:days',      @onRecalc
        @listenTo @model, 'change:dailyRate', @onRecalc

        @listenTo @organization, 'sync', _.partial(@loaded, 'organization')
        @listenTo @organization.get('customers'), 'add',  @onCustomerCreated
        @listenTo @organization.get('customers'), 'sync',  _.partial(@loaded, 'customers')
        @listenTo @organization.get('deposits'), 'add',  @onDepositCreated
        @listenTo @organization.get('deposits'), 'sync',  _.partial(@loaded, 'deposits')

        @initData()

      onCustomerCreated: (model)->
        return if @$('#customer-existing-radio').prop('checked')
        @$('#customer-existing-radio').click()
        @$('.customer-portlet .portlet-title .tools a').click() if @$('.customer-portlet .portlet-title .tools a').hasClass('collapse')
        @initCustomerSelect2()
        @ui.customerSearch.select2 'val', model.get 'contactID'

        @customer_region.show new CustomerView model: model, organization: @organization
        @ui.vehicleSearch.select2 'open'

      onDepositCreated: (model)->
        return unless @model.get('customer')
        @initDepositSelect2()
        @ui.depositSearch.select2 'val', model.get 'itemID'
        @$('#deposit-existing-radio').click()
        @$('.deposit-portlet .portlet-title .tools a').click() if @$('.deposit-portlet .portlet-title .tools a').hasClass('collapse')
        @deposit_region.show new DepositView model: model, organization: @organization


      loaded:(target)->
        @dataCollection[target] = true
        unless false in _.values(@dataCollection)
          @$el.trigger "loaded"

      onShow:->
        @stickit()
        @customer_region.show new CustomerView model: new CustomerModel(), organization: @organization

      initData: ->
        @fetchOrganization()
        @fetchCustomers()
        @fetchDeposits()

      initViewElements:->
        @initCustomerSelect2()
        @initVehicleSelect2()
        @initDepositSelect2()

      showFetchError: (target, data)->
        toastr.error "Error getting #{target} data"
        console.error "error fetching #{target} data", data

      fetchOrganization: ->
        @organization.fetch()
          .success (data)-> console.log "org loaded"
          .error   (data)=> @showFetchError 'Organization'

      fetchCustomers: ->
        @organization.get('customers').fetch()
          .success (data)-> console.log "customers loaded"
          .error   (data)=> @showFetchError 'Customers'

      fetchDeposits: ->
        @organization.get('deposits').fetch()
          .success (data)-> console.log "deposits loaded"
          .error   (data)=> @showFetchError 'Deposits', data

      onCustomerSearch: (e)->
        id = $(e.currentTarget).val()
        if id
          # debugger
          @model.set 'customer', 'contactID': id
          @currentCustomer = @organization.get('customers').get(id)
          console.log @currentCustomer
          @customer_region.show new CustomerView model:@currentCustomer, organization: @organization

      onVehicleSearch: (e)->
        id = $(e.currentTarget).val()
        if id
          @model.set 'vehicle', "itemID": id
          console.log @model.get 'vehicle'
          @currentVehicle = @organization.get('vehicles').get(id)

          @model.set 'startMileage', @currentVehicle.get('currentMileage')
          console.log @currentVehicle
          @vehicle_region.show new VehicleView model: @currentVehicle


      onDepositSearch: (e)->
        id = $(e.currentTarget).val()

        if id
          @model.set 'deposit', "itemID": id
          @currentDeposit = @organization.get('deposits').get(id)
          console.log @currentDeposit
          @deposit_region.show new DepositView model: @currentDeposit, organization: @organization

      initCustomerSelect2: ()->
        @ui.customerSearch.parent().parent().removeClass "loading-select2"
        @ui.customerSearch.select2('destroy') if @ui.customerSearch.data('select2')
        @ui.customerSearch.select2
          data: @organization.get('customers').toArray()
          minimumInputLength: 1
        unless @ui.customerSearch.select2('val')?
          @ui.customerSearch.select2('open')

      vehiclesToArray: ->
        result = _.map @organization.get('vehicles').models, (vehicle)->
          id: vehicle.get('itemID'), text: vehicle.get('color') + ", " + vehicle.get('model') + ", " + vehicle.get('make') + ", " + vehicle.get('year') + ", " + vehicle.get('plateNumber')
        result.unshift id: 0, text:""
        result

      initVehicleSelect2: ()->
        @ui.vehicleSearch.select2('destroy') if @ui.vehicleSearch.data('select2')
        @ui.vehicleSearch.select2
          data: @vehiclesToArray()
          minimumInputLength: 1

      depositsToArray: ()->
        result = _.filter @organization.get('deposits').models, (deposit)-> deposit.get('status') is "ACTIVE"
        result = _.map result, (deposit)->
          id: deposit.get('itemID'), text: deposit.get('customer').firstName + ", (" + deposit.get('itemID') + ")"
        result.unshift id: 0, text:""
        result

      initDepositSelect2: ()->
        @ui.depositSearch.select2('destroy') if @ui.depositSearch.data('select2')
        @ui.depositSearch.select2
          data: @depositsToArray()
          minimumInputLength: 1

      customerChoiceChange: (e)->
        if e.currentTarget.value == "new"
          $(e.currentTarget).closest('.portlet').find('input[name$="_search"]').val("").parent().hide()
          @ui.customerSearch.select2 'val', ''
          @currentCustomer = new CustomerModel()
          @customer_region.show new CustomerView model: @currentCustomer, organization: @organization
          if $('.customer-portlet .portlet-title .tools a:first').hasClass('expand')
            $('.customer-portlet .portlet-title .tools a').click()
        else
          $(e.currentTarget).closest('.portlet').find('input[name$="_search"]').parent().show()
          @customer_region.reset()
          @$('.customer-portlet .portlet-title .tools a').click()

          unless @ui.customerSearch.select2('val')?
            setTimeout (=> @ui.customerSearch.select2('open')),100

      depositChoiceChange: (e)->
        if e.currentTarget.value == "new"
          $(e.currentTarget).closest('.portlet').find('input[name$="_search"]').val("").parent().hide()
          @ui.depositSearch.select2 'val', ''
          @deposit_region.show new DepositView model: new DepositModel(), organization: @organization
          if @$('.deposit-portlet .portlet-title .tools a:first').hasClass('expand')
            @$('.deposit-portlet .portlet-title .tools a').click()
        else
          $(e.currentTarget).closest('.portlet').find('input[name$="_search"]').parent().show()
          @deposit_region.reset()
          @$('.deposit-portlet .portlet-title .tools a').click()

          unless @ui.depositSearch.select2('val')?
            setTimeout (=> @ui.depositSearch.select2('open')),100

      onCustomerChange: ->
        if @model.get('customer')?.contactID?.length
          @showVehicleChoice()
        else
          @hideVehicleChoice()

      onVehicleChange: ->
        if @model.get('vehicle')?.itemID?.length
          @showDepositChoice()
          model = @organization.get('vehicles').get(@model.get('vehicle')?.itemID)
          @model.set 'dailyRate', model.get('dailyRate') or "50"
        else
          @hideDepositChoice()

      onDepositChange: ->
        if @model.get('deposit')?.itemID?.length
          @showAgreementDetails()
        else
          @hideAgreementDetails()

      showVehicleChoice: ->
        @$('.vehicle-portlet').removeClass('hidden')
        @ui.vehicleSearch.select2('open')

      hideVehicleChoice: ->
        @$('.vehicle-portlet').removeClass('hidden').addClass('hidden')

      showDepositChoice: ->
        @$('.deposit-portlet').removeClass('hidden')
        @ui.depositSearch.select2('open')

      hideDepositChoice: ->
        @$('.deposit-portlet').removeClass('hidden').addClass('hidden')

      showAgreementDetails: ->
        @$('.agreement-details-portlet').removeClass('hidden')

      hideAgreementDetails: ->
        @$('.agreement-details-portlet').removeClass('hidden').addClass('hidden')

      onRecalc: ->
        @model.recalc()

      onSubmit: (e)->
        e.preventDefault()
        @model.save()
          .success (data)=>
            # debugger
            @ui.vehicleSearch.select2 'close'
            @ui.depositSearch.select2 'close'
            toastr.success "Successfully Created Rent Agreement"
            console.log "successfully created rental", data
          .error (data)->
            toastr.error "Error Creating Rent Agreement"
            console.log "error creating rental", data


  App.CarRentAgreement.RentAgreement
