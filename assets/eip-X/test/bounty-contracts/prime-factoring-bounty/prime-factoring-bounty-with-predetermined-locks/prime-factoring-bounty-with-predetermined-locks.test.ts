import getBountyTest from '../../bounty-test-factory'
import PrimeFactoringBountyWithPredeterminedLocksUtils from './prime-factoring-bounty-with-predetermined-locks-utils'

const bountyUtils = new PrimeFactoringBountyWithPredeterminedLocksUtils()

describe('PrimeFactoringBountyWithPredeterminedLocks', getBountyTest(bountyUtils))
