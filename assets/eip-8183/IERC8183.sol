// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.20;

/// @title IERC8183 — Agentic Commerce Protocol
/// @notice Standard interface for job contracts between clients and AI agent providers.
/// @dev EIP-8183 DRAFT (2026-03-11). Requires EIP-165. Recommends ERC-8004.
///      Placeholder interfaceId: 0x81830001 (final to be assigned by EIP editors).
interface IERC8183 {

    // ── Enumerations ──────────────────────────────────────────────────────────

    enum Status { Open, Funded, Submitted, Completed, Rejected, Expired }

    // ── Structs ───────────────────────────────────────────────────────────────

    struct Job {
        address client;
        address provider;    // address(0) if not yet assigned
        address evaluator;
        address token;       // address(0) = ETH; ERC-20 address otherwise
        uint256 budget;
        uint256 expiredAt;   // unix timestamp
        Status  status;
        string  description;
        string  deliverable; // set by provider on submit()
        string  reason;      // set by evaluator on complete() or reject()
    }

    // ── Events ────────────────────────────────────────────────────────────────

    event JobCreated(
        uint256 indexed jobId,
        address indexed client,
        address evaluator,
        string  description
    );

    event BudgetSet(uint256 indexed jobId, uint256 amount, address token);
    event JobFunded(uint256 indexed jobId, uint256 amount);
    event ProviderSet(uint256 indexed jobId, address indexed provider);

    event WorkSubmitted(
        uint256 indexed jobId,
        address indexed provider,
        string  deliverable
    );

    event JobCompleted(
        uint256 indexed jobId,
        address indexed provider,
        uint256 payment,
        string  reason
    );

    event JobRejected(uint256 indexed jobId, string reason);
    event JobExpired(uint256 indexed jobId);

    // ── Write Functions ────────────────────────────────────────────────────────

    /// @notice Create a new job.
    /// @param provider   Agent that will do the work. MAY be address(0).
    /// @param evaluator  Address that attests completion/rejection. MUST NOT be address(0).
    /// @param token      ERC-20 token address, or address(0) for ETH.
    /// @param budget     Payment amount. MAY be 0 if set later via setBudget().
    /// @param expiredAt  Unix timestamp after which client MAY call claimRefund().
    /// @param description Human- or machine-readable job brief.
    /// @return jobId     Monotonically increasing identifier.
    function createJob(
        address provider,
        address evaluator,
        address token,
        uint256 budget,
        uint256 expiredAt,
        string  calldata description
    ) external returns (uint256 jobId);

    /// @notice Set or update budget. MUST revert if status != Open.
    function setBudget(uint256 jobId, uint256 amount) external;

    /// @notice Assign or reassign provider. MUST revert if status != Open.
    function setProvider(uint256 jobId, address provider) external;

    /// @notice Fund escrow. Moves Open → Funded.
    ///         ETH: msg.value MUST equal job.budget.
    ///         ERC-20: caller MUST have approved this contract for job.budget.
    function fund(uint256 jobId) external payable;

    /// @notice Provider submits deliverable. Moves Funded → Submitted.
    function submit(uint256 jobId, string calldata deliverable) external;

    /// @notice Evaluator completes job. Moves Submitted → Completed. Pays provider.
    function complete(uint256 jobId, string calldata reason) external;

    /// @notice Evaluator rejects job. Moves Funded/Submitted → Rejected. Refunds client.
    function reject(uint256 jobId, string calldata reason) external;

    /// @notice Anyone claims refund after expiry. Moves Funded/Submitted → Expired.
    function claimRefund(uint256 jobId) external;

    // ── Read Functions ────────────────────────────────────────────────────────

    function getJob(uint256 jobId) external view returns (Job memory);
    function isExpired(uint256 jobId) external view returns (bool);
}
