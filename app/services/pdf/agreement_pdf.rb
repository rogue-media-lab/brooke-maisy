module Pdf
  class AgreementPdf < Base
    private

    def draw_body(pdf)
      pdf.move_down 20

      pdf.text "DESIGN & INSTALLATION SERVICES AGREEMENT", style: :bold, size: 16, align: :center, color: "776B63"
      pdf.move_down 16

      pdf.text "This Design & Installation Services Agreement (\"Agreement\") is made as of #{formatted_date}, by and between Brooke & Maisy Interior Designs, LLC, a South Carolina limited liability company (\"Designer\"), and #{client_name} (\"Client\"), collectively the \"Parties.\" Client's project address (\"Project Location\"): #{project_location}.", size: 10
      pdf.move_down 12

      sections.each_with_index do |(title, body), i|
        pdf.text "#{i + 1}. #{title}", style: :bold, size: 10, color: "776B63"
        pdf.text body, size: 9
        pdf.move_down 8
      end

      pdf.move_down 12
      pdf.text "Acknowledgment", style: :bold, size: 11, color: "776B63"
      pdf.text "By signing below, Client acknowledges having read and understood this Agreement, including all terms and conditions, and confirms having been informed of the right to cancel described in Section 6. Client will receive a signed and dated copy of this Agreement.", size: 9
      pdf.move_down 24

      draw_signature_blocks(pdf)
    end

    def draw_signature_blocks(pdf)
      pdf.text "Client Signature: _______________________________________             Date: ______________", size: 10
      pdf.move_down 16
      pdf.text "Print Name: _____________________________________________", size: 10
      pdf.move_down 24
      pdf.text "Designer Signature: _____________________________________             Date: ______________", size: 10
      pdf.move_down 16
      pdf.text "Print Name: Amanda Nelson, Owner — Brooke & Maisy Interior Designs, LLC", size: 10
    end

    def sections
      [
        [ "Scope of Services",
          "Designer agrees to provide interior design and, where applicable, installation services (\"Services\") as described in the Work Order, design plan, proposal, or estimate provided to Client and incorporated into this Agreement by reference (\"Work Order\"). The Work Order will describe the specific rooms, products, materials, and scope of work for the project. Where installation work is required, Designer may perform the installation directly or, at Designer's discretion, engage a licensed and insured third-party subcontractor (\"Subcontractor\") to perform all or part of the installation. Designer remains responsible for coordinating and overseeing any Subcontractor's work under this Agreement." ],
        [ "Fees, Deposit & Payment",
          "Client agrees to pay Designer the fees set forth in the Work Order or proposal, which may include a design fee, hourly rate, percentage markup on furnishings and materials, and/or a flat project fee, as specified for the applicable project. Unless otherwise stated in the Work Order: A non-refundable design retainer of 50% of the estimated project cost (or $1000, whichever is greater) is due upon signing this Agreement before design work begins. A deposit of 50% of the total product/materials cost is due prior to Designer placing any custom or special orders. The remaining balance is due upon substantial completion of the Services, unless a different milestone payment schedule is set out in the Work Order. Designer accepts payment by cash, check, or credit card. A processing fee may apply to credit card payments where permitted by law. Any amount not paid when due will accrue interest at 1% per month (or the maximum rate permitted by law, if lower) until paid in full. If Client's account is referred to a collection agency or attorney for collection, Client agrees to pay all reasonable costs of collection, including attorneys' fees, to the extent permitted by law." ],
        [ "Change Orders",
          "Any change to the scope of services, materials, or pricing after the Work Order is signed must be documented in a written change order signed by both Parties before the change is made. Change orders may affect the project price and estimated timeline." ],
        [ "Project Timeline",
          "Design work will begin within approximately 3 business days of the Effective Date and receipt of the design retainer. Installation, if applicable, will commence on the approximate start date set out in the Work Order and is expected to be substantially completed within approximately 8 weeks of the installation start date, subject to Section 5 (Permissible Delays). All dates are estimates, not guarantees, given the custom nature of the work." ],
        [ "Permissible Delays",
          "Designer may extend any estimated start or completion date due to circumstances beyond Designer's reasonable control, including but not limited to: manufacturer or supplier delays; shipping damage or delay; production errors; permitting or inspection delays; pre-existing or hazardous conditions at the Project Location; inclement weather or acts of God; labor or material shortages; change orders or additional work requested by Client; Client's failure to provide timely access to the Project Location; and other delays outside Designer's or any Subcontractor's reasonable control. Designer will notify Client of any material delay and provide a revised estimate." ],
        [ "Right to Cancel",
          "YOU, THE CLIENT, MAY CANCEL THIS TRANSACTION, WITHOUT ANY PENALTY OR OBLIGATION, WITHIN THREE (3) BUSINESS DAYS FROM THE DATE YOU SIGN THIS AGREEMENT, IF THIS AGREEMENT WAS SIGNED AT A LOCATION OTHER THAN DESIGNER'S PLACE OF BUSINESS (INCLUDING YOUR HOME). SEE THE ATTACHED NOTICE OF CANCELLATION FORM FOR YOUR RIGHTS UNDER THIS SECTION. If Client cancels within this period, any payments made and any goods traded in will be returned within ten (10) business days of Designer's receipt of the cancellation notice, and any security interest arising from the transaction will be released. To cancel, Client must send a signed and dated written notice to Designer at the email or address listed in Section 18 (Notices). This cancellation right applies as required by the FTC Cooling-Off Rule and South Carolina law for applicable in-home sales transactions. Designer recommends confirming the specific triggering conditions and required notice forms with legal counsel, as they may vary based on where and how the Agreement is signed." ],
        [ "Return Policy",
          "Special-order merchandise, custom merchandise, and installed merchandise cannot be returned or refunded once the right-to-cancel period in Section 6 has expired, except as required by an applicable manufacturer warranty." ],
        [ "Client Responsibilities; Site Access",
          "Client agrees to provide Designer and any Subcontractor with reasonable, uninterrupted access to the Project Location as needed to perform the Services. Client is responsible for removing or protecting furniture, art, flooring, and other items in the work area unless Designer agrees in writing to do so. Client represents that Client either holds legal title to the Project Location or has written consent from each owner of the property for the Services to be performed." ],
        [ "Pre-Existing & Hazardous Conditions",
          "Designer is not responsible for pre-existing conditions at the Project Location, including non-code-compliant work performed by others. If Designer discovers an unforeseen structural defect or pre-existing condition that affects the project, Designer may submit a change order describing the additional work, cost, and schedule impact. If Client declines the change order, Designer may cancel the affected Services, and Client agrees to pay for materials, labor, and services provided, and any permit fees incurred, through the date of cancellation. If Designer suspects mold, asbestos, or another hazardous condition at the Project Location, Designer will stop work in the affected area and will not test, repair, or remediate the condition. Client must have the condition tested and remediated by a qualified third party, at Client's expense, before work resumes, or Designer may cancel the affected Services on the same payment terms described above. Client agrees to notify Designer in writing of any known hazardous conditions at the Project Location before work begins." ],
        [ "Permits & Approvals",
          "Designer will notify Client of any permits reasonably known to be required by state or local codes for the Services. Unless otherwise required by law, Designer will obtain required permits at Client's expense. Client is solely responsible for obtaining any approvals required by a homeowners' association, community association, or historic district commission before work begins, and for informing Designer of any such requirements." ],
        [ "Materials & Product Characteristics",
          "Client acknowledges that fabrics, finishes, wood, stone, and other natural or dyed materials may vary in color, grain, and texture from samples due to dye-lot variation, lighting, and the natural characteristics of the material. Designer will use reasonable efforts to match samples but does not guarantee an exact match. Product specifications, availability, and lead times are subject to change by the manufacturer without notice." ],
        [ "Design Materials & Intellectual Property",
          "All design concepts, floor plans, mood boards, renderings, specifications, and related materials created by Designer (\"Design Materials\") remain the intellectual property of Designer unless otherwise agreed in writing. Client receives a license to use the Design Materials solely for the completion and personal use of the Project. Design Materials may not be reproduced, distributed, or used for any other project without Designer's written consent." ],
        [ "Photographs & Portfolio Use",
          "Client consents to Designer photographing and video recording the Project Location before, during, and after the Services to document project progress. Designer may also use such photographs and videos in its portfolio, website, social media, and marketing materials, unless Client opts out in writing prior to the start of the Services. Client's name and specific address will not be published without separate written consent." ],
        [ "Warranties",
          "Designer warrants its own labor for a period of one (1) year from the date of installation against defects in workmanship. Repairs needed after the first year are Client's responsibility unless otherwise stated in writing. Manufacturer product warranties are the responsibility of the manufacturer, not Designer; some manufacturer warranties cover parts but not labor. Designer's warranty is voided if any third party other than Designer or its Subcontractor alters, services, or repairs the installed product. If Client believes any work is defective, Client must notify Designer within 30 days of discovering the issue and within the applicable warranty period, using the contact information in Section 18. Client agrees to give Designer a reasonable opportunity to inspect the alleged defect. If Designer confirms a valid claim, Designer will, at its option, repair, reinstall, re-perform the work, or refund the applicable purchase price." ],
        [ "Insurance",
          "Designer represents that it carries general liability insurance applicable to its design and installation operations and will provide Client with a certificate of insurance upon request. Client is responsible for maintaining Client's own homeowner's or property insurance covering the Project Location throughout the Services." ],
        [ "Limitation of Liability",
          "TO THE FULLEST EXTENT PERMITTED BY LAW, DESIGNER AND ANY SUBCONTRACTOR WILL NOT BE LIABLE TO CLIENT FOR ANY INCIDENTAL, INDIRECT, CONSEQUENTIAL, OR SPECIAL DAMAGES ARISING OUT OF THIS AGREEMENT OR THE SERVICES. DESIGNER'S AND ANY SUBCONTRACTOR'S TOTAL LIABILITY TO CLIENT UNDER THIS AGREEMENT WILL NOT EXCEED THE TOTAL AMOUNT CLIENT HAS PAID TO DESIGNER UNDER THIS AGREEMENT." ],
        [ "Indemnification",
          "Client agrees to indemnify and hold Designer harmless from any claims, damages, or expenses (including reasonable attorneys' fees) arising from Client's breach of this Agreement, Client's failure to disclose a known hazardous or unsafe condition at the Project Location, or Client's provision of inaccurate information about ownership or authority to permit the Services. Designer agrees to indemnify and hold Client harmless from claims arising from Designer's negligence or willful misconduct in performing the Services, to the extent not otherwise limited by Section 16." ],
        [ "Interference; Cancellation by Designer; Notices",
          "Designer may cancel this Agreement if Designer reasonably determines that the project cannot be completed as intended due to site conditions, Client's unreasonable interference with the Services, or an unsafe, threatening, or offensive environment encountered at the Project Location. If Designer cancels under this section or Section 9, Client agrees to pay for materials, labor, and services provided, and any permit fees incurred, through the date of cancellation. All notices under this Agreement, including cancellation notices, must be sent in writing to: Brooke & Maisy Interior Designs, LLC, Attn: Amanda Nelson, 1726 Gold Hill Rd. #1071, Fort Mill, SC. 29708 amanda@brookenmaisy.com, (980)277-0709." ],
        [ "Liens",
          "Designer or its Subcontractor may have a claim against Client's property under applicable South Carolina mechanic's lien laws if amounts due under this Agreement are not paid." ],
        [ "Financed or Credit Card Purchases",
          "If Client uses a credit card or third-party financing to pay for any part of this Agreement, Client acknowledges that the related cardholder agreement or financing terms may add interest or fees beyond the Agreement price, and that Designer is not a party to those agreements." ],
        [ "Rebates & Incentives",
          "Designer is not a party to any manufacturer, utility, or government rebate, credit, or incentive program, and is not responsible if such an offer is denied, delayed, or paid in a different amount than expected. Client is responsible for completing any related applications, though Designer may assist upon request." ],
        [ "Dispute Resolution; Governing Law",
          "This Agreement is governed by the laws of the State of South Carolina, without regard to conflict-of-law principles. Before filing a lawsuit, the Parties agree to attempt in good faith to resolve any dispute through informal negotiation, and, if unresolved after 30 days, through mediation in York County, South Carolina, before either Party pursues other remedies. Nothing in this section prevents neither Party from seeking emergency or injunctive relief where necessary." ],
        [ "General Provisions",
          "Entire Agreement: This Agreement, together with the Work Order and any signed change orders, is the entire agreement between the Parties and supersedes all prior discussions or understandings, whether oral or written. Severability: If any provision of this Agreement is found unenforceable, the remaining provisions will remain in full force and effect. Assignment: Client may not assign this Agreement without Designer's written consent. Designer may assign its rights to a Subcontractor solely for purposes of performing the Services. No Waiver: Designer's failure to enforce any provision of this Agreement is not a waiver of that provision. Termination After Cancellation Period: If either Party terminates this Agreement after the right-to-cancel period in Section 6 has expired, Client agrees to pay Designer for materials, labor, and services provided, and any permit fees incurred, through the date of termination." ]
      ]
    end
  end
end
