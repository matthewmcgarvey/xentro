component BuyAddressTransaction {
  connect WalletStore exposing { currentWallet, currentWalletConfig }

  connect TransactionStore exposing {
    sendError,
    sendSuccess,
    resetStatus,
    resetErrorSuccess,
    reset,
    senderPrivatePublic,
    createBuyAddressTransaction,
    sendTransaction,
    domainExists,
    setDomainError,
    domainError
  }

  property senderAddress : String
  property readable : Array(String) = []
  property tokens : Array(Token)

  state name : String = ""
  state nameError : String = ""
  state feeError : String = ""
  state speed : String = currentWalletConfig.speed
  state confirmCheck : Bool = false

  fun componentDidMount : Promise(Never, Void) {
    resetErrorSuccess()
  }

  fun componentDidUpdate : Promise(Never, Void) {
    if (reset) {
      sequence {
        next
          {
            name = "",
            speed = currentWalletConfig.speed,
            confirmCheck = false,
            nameError = ""
          }

        resetStatus(false)
      }
    } else {
      Promise.never()
    }
  }

  fun onName (event : Html.Event) {
    sequence {
      next
        {
          name = value,
          nameError = validateName(value),
          feeError = validateFeeAmount
        }

      setDomainError("")
    }
  } where {
    value =
      Dom.getValue(event.target)
  }

  fun onDomain (event : Html.Event) {
    domainExists(currentWalletConfig.node, value)
  } where {
    value =
      Dom.getValue(event.target)
  }

  fun validateName (value : String) : String {
    try {
      regexResult =
        Regexp.create("^[a-zA-Z0-9]{1,20}\.ax")
        |> Regexp.match(value)

      if (regexResult) {
        ""
      } else {
        "Please comply with the rules for a name listed above"
      }
    }
  }

  fun onCheck (event : Html.Event) {
    next { confirmCheck = !confirmCheck }
  } where {
    value =
      Dom.getValue(event.target)
  }

  get validateFeeAmount : String {
    try {
      tokenAmount =
        tokens
        |> Array.find(
          (token : Token) : Bool {
            String.toLowerCase(token.name) == String.toLowerCase("axnt")
          })
        |> Maybe.map((token : Token) : Maybe(Number) { Number.fromString(token.amount) })
        |> Maybe.flatten
        |> Maybe.withDefault(0)

      if (0.0001 > tokenAmount) {
        "You don't have enough AXNT to pay the transaction fee of 0.0001"
      } else {
        ""
      }
    }
  }

  get buyButtonState : Bool {
    String.isEmpty(name) || !confirmCheck || !String.isEmpty(nameError) || !String.isEmpty(domainError) || !String.isEmpty(feeError)
  }

  get rules : Html {
    <div/>
  }

  fun processSendTransaction (
    event : Html.Event,
    baseUrl : String,
    recipientAddress : String,
    senderWif : String,
    transaction : Transaction
  ) {
    sequence {
      next { confirmCheck = false }
      sendTransaction(event, baseUrl, recipientAddress, senderWif, transaction)
    }
  }

  fun render {
    if (Array.isEmpty(readable)) {
      getAddressView()
    } else {
      alreadyHaveAddressView()
    }
  }

  fun alreadyHaveAddressView : Html {
    <div class="card border-dark mb-3">
      <div class="card-body">
        <h4 class="card-title">
          "Buy Human Readable Address"
        </h4>

        <div
          class="alert alert-info alert-with-border"
          role="alert">

          <p>"You may only have 1 human readable address per wallet address."</p>

        </div>
      </div>
    </div>
  }

  fun getAddressView : Html {
    <div class="card border-dark mb-3">
      <div class="card-body">
        <h4 class="card-title">
          "Buy Human Readable Address"
        </h4>

        <div
          class="alert alert-info alert-with-border"
          role="alert">

          <p>"Please select a name within the following restrictions:"</p>

          <hr/>

          <p class="mb-0">
            <ul class="ml-3">
              <li>"- Can only contain alphanumerics"</li>

              <li>
                "- Must end with the suffix: "

                <b>".ax"</b>

                " (e.g. myname.ax)"
              </li>

              <li>"- Length must be between 1 and 20 characters (excluding suffix)"</li>
            </ul>
          </p>

        </div>

        <{ UiHelper.errorAlert(sendError) }>
        <{ UiHelper.successAlert(sendSuccess) }>

        <div>
          <div class="form-row mb-3">
            <div class="col-md-8 mb-6">
              <label for="recipient-address">
                "Name of human readable address"
              </label>

              <input
                type="text"
                class="form-control"
                id="address-name"
                placeholder="Human readable address"
                onBlur={onDomain}
                onInput={onName}
                value={name}/>

              <div class="mt-1">
                <{ UiHelper.errorAlert(nameError) }>
              </div>

              <div class="mt-1">
                <{ UiHelper.errorAlert(domainError) }>
              </div>

              <div class="mt-1">
                <{ UiHelper.errorAlert(feeError) }>
              </div>
            </div>
          </div>

          <div class="form-group">
            <div class="custom-control custom-checkbox custom-checkbox-success">
              <input
                type="checkbox"
                onChange={onCheck}
                class="custom-control-input"
                checked={confirmCheck}
                id="customCheck2"/>

              <label
                class="custom-control-label"
                for="customCheck2">

                "I've double checked everything is correct!"

              </label>
            </div>
          </div>

          <button
            onClick={(e : Html.Event) { processSendTransaction(e, currentWalletConfig.node, senderAddress, senderWif, transaction) }}
            class="btn btn-secondary"
            disabled={buyButtonState}
            type="submit">

            "Buy"

          </button>
        </div>
      </div>
    </div>
  } where {
    senderInfo =
      senderPrivatePublic(currentWallet)

    senderPublicKey =
      senderInfo.publicKey

    senderWif =
      senderInfo.wif

    transaction =
      createBuyAddressTransaction(senderAddress, senderPublicKey, name, speed)
  }
}
