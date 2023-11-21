import getBountyTest from '../../bounty-test-factory'
import OrderFindingBountyWithPredeterminedLocksUtils from './order-finding-bounty-with-predetermined-locks-utils'

const bountyUtils = new OrderFindingBountyWithPredeterminedLocksUtils()

describe('OrderFindingBountyWithPredeterminedLocks', getBountyTest(bountyUtils))
