//SPDX-License-Identifier: MIT 

pragma solidity 0.8.30;

/**
 * @title KipuBank
 * @author Ariel Rodríguez
 * @notice TP final del módulo 2 del curso de Ethereum de EthKipu
 * @notice Es una simulación de banco con depósitos y extracción
 */
contract KipuBank{
    ///@notice Mapping que mantiene el balance de la cuenta
    mapping (address user => uint256 amount) s_balances;
    ///@notice Mapping que mantiene la cantidad de depósitos de la cuenta
    mapping (address user => uint32 counter) s_deposits;
    ///@notice Mapping que mantiene la cantidad de extracciones de la cuenta
    mapping (address user => uint32 counter) s_withdrawals;
    
    ///@notice Límite de balance por cuenta
    uint32 public immutable s_bankCap;
    uint24 public immutable s_withdrawLimit = 10000000; 

    ///@notice Evento emitido al intentar depositar
    event DepositRequest(address from, uint amount);
    ///@notice Evento emitido tras depositar con éxito
    event Deposited(address from, uint amount);
    ///@notice Evento emitido al intentar extraer
    event ExtractionRequest(address to, uint amount);
    ///@notice Evento emitido tras extraer con éxito
    event Extracted(address to, uint amount);



    ///@notice Error emitido al intentar depositar una cantidad inválida (== 0, >bankCap)
    error DepositNotAllowed(address to, uint amount);
    ///@notice Error emitido al intentar extraer una cantidad inválda (<=0, >saldo, >withdrawLimit)
    error ExtractionNotAllowed(address to, uint amount);
    ///@notice Error emitido cuando falla una extracción
    error ExtractionReverted(address to, uint amount, bytes errorData);



    /**
        *@notice Constructor que recibe el bankCap como parámetro
        *@param _bankCap es el máximo que podría tener el contrato en total
    */
    constructor(uint32 _bankCap) {
        s_bankCap = _bankCap;
    }



    /**
        *@notice Función pública para ver el balance que uno mismo tiene
    */
    function getBalance() external view returns(uint balance_) {
        balance_ = s_balances[msg.sender];
    }
    
    /**
        *@notice Función pública para ver la cantidad de depósitos que uno hizo
    */
    function getDeposits() external view returns(uint deposits_) {
        deposits_ = s_deposits[msg.sender];
    }

    /**
        *@notice Función pública para ver la cantidad de extracciones que uno hizo
    */
    function getWithdrawals() external view returns(uint withdrawals_) {
        withdrawals_ = s_withdrawals[msg.sender];
    }

    /**
        *@notice Función para hacer un depósito
		*@notice Sólo se puede depositar un valor >0 y <=bankCap
    */
    function deposit() public payable {
        emit DepositRequest(msg.sender, msg.value);
        require(msg.value > 0, DepositNotAllowed(msg.sender,msg.value));
        require(msg.value <= s_bankCap, DepositNotAllowed(msg.sender,msg.value));

        s_balances[msg.sender] += msg.value;
        s_deposits[msg.sender]++;
        
        emit Deposited(msg.sender, msg.value);
    }

    /**
        *@notice Función para hacer una extracción
		*@dev Sólo se puede extraer un valor mayor a 0, siempre que no se supere el bankCap
        *@param amount_ Cantidad que se quiere extraer. Debe ser <= al balance y al límite de extracción
    */
    function withdraw(uint amount_) public {
        emit ExtractionRequest(msg.sender, amount_);
        require(amount_ > 0, ExtractionNotAllowed(msg.sender, amount_));
        require(amount_ <= s_balances[msg.sender], ExtractionNotAllowed(msg.sender, amount_));
        require(amount_ <= s_withdrawLimit, ExtractionNotAllowed(msg.sender, amount_));
        
        s_balances[msg.sender] -= amount_;
        s_withdrawals[msg.sender]++;
        
        transferFunds(amount_);
        
        emit Extracted(msg.sender, amount_);        
    }

    /**
        *@notice Función privada que transfiere la cantidad pedida por la extracción
		*@dev Nadie puede acceder a esta función excepto ESTE contrato
        *@param amount_ Cantidad a transferir
    */
    function transferFunds(uint amount_) private {
        (bool success, bytes memory errorData) = msg.sender.call{value: amount_}("");
        require(success, ExtractionReverted(msg.sender,amount_,errorData));
    }
}