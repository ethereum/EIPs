import getBountyTests from '../../bounty-test-factory'
import SignatureBountyUtils from './signature-bounty-with-predetermined-locks-utils'

const bountyUtils = new SignatureBountyUtils()

describe('SignatureBountyWithPredeterminedLocks', getBountyTests(bountyUtils))
